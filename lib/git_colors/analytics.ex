defmodule GitColors.Analytics do
  @moduledoc """
  Context module for commit analytics and statistics calculations.

  This module provides functions for analyzing git commit data, including:
  - Commit type and sentiment analysis
  - Word count statistics
  - AI generation detection
  - Contributor analysis
  - Distribution calculations
  """

  @doc """
  Calculates comprehensive statistics for a list of commits.

  Returns a map containing various analytics including type distribution,
  sentiment analysis, complexity metrics, contributor stats, and more.
  """
  def get_commit_analysis_stats(commits) do
    analyses = Enum.map(commits, & &1.analysis)

    %{
      type_distribution: calculate_distribution(analyses, & &1.type),
      sentiment_distribution: calculate_distribution(analyses, & &1.sentiment),
      complexity_distribution: calculate_distribution(analyses, & &1.complexity),
      breaking_changes: Enum.count(analyses, & &1.has_breaking_change),
      total_commits: length(commits),
      revert_stats: calculate_revert_stats(analyses, commits),
      word_count_stats: calculate_word_count_stats(analyses),
      ai_generation_stats: calculate_ai_stats(analyses, commits),
      contributor_stats: calculate_contributor_stats(commits)
    }
  end

  @doc """
  Extracts colors from a list of commits or color strings.
  """
  def extract_colors(commits) do
    Enum.map(commits, fn
      %{color: color} -> color
      color when is_binary(color) -> color
    end)
  end

  @doc """
  Finds the most common color from a list of commits.

  ## Examples

      iex> commits = [%{color: "ff0000"}, %{color: "00ff00"}, %{color: "ff0000"}]
      iex> GitColors.Analytics.get_most_common_color(commits)
      "ff0000"

      iex> colors = ["ff0000", "00ff00", "ff0000"]
      iex> GitColors.Analytics.get_most_common_color(colors)
      "ff0000"
  """
  def get_most_common_color(commits) when is_list(commits) do
    commits
    |> Enum.map(fn
      %{color: color} -> color
      color when is_binary(color) -> color
    end)
    |> Enum.frequencies()
    |> Enum.max_by(fn {_color, count} -> count end)
    |> elem(0)
  end

  @doc """
  Finds the most common commit type from a list of analyses.
  """
  def get_most_common_type(analyses) do
    if length(analyses) > 0 do
      analyses
      |> Enum.group_by(& &1.type)
      |> Enum.max_by(fn {_type, list} -> length(list) end)
      |> elem(0)
    else
      "unknown"
    end
  end

  # Private helper functions

  defp calculate_distribution(analyses, selector_fn) do
    analyses
    |> Enum.group_by(selector_fn)
    |> Enum.map(fn {key, list} -> {key, length(list)} end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
  end

  defp calculate_word_count_stats(analyses) do
    word_counts = Enum.map(analyses, & &1.word_count)

    %{
      average: safe_average(word_counts),
      max: safe_max(word_counts),
      min: safe_min(word_counts),
      total_words: Enum.sum(word_counts)
    }
  end

  defp calculate_ai_stats(analyses, commits) do
    ai_generated_counts = calculate_distribution(analyses, & &1.is_ai_generated)
    likely_ai_count = Enum.count(analyses, &(&1.is_ai_generated in ["likely", "highly_likely"]))

    %{
      distribution: ai_generated_counts,
      likely_ai_count: likely_ai_count,
      likely_ai_percentage: safe_percentage(likely_ai_count, length(commits))
    }
  end

  defp calculate_revert_stats(analyses, commits) do
    revert_count = Enum.count(analyses, &(&1.type == "revert"))

    %{
      count: revert_count,
      percentage: safe_percentage(revert_count, length(commits))
    }
  end

  defp calculate_contributor_stats(commits) do
    commits
    |> Enum.group_by(&normalize_author/1)
    |> Enum.map(&build_contributor_stat(&1, length(commits)))
    |> Enum.sort_by(& &1.commit_count, :desc)
    |> Enum.take(5)
  end

  defp normalize_author(%{author: nil}), do: "Unknown Author"
  defp normalize_author(%{author: ""}), do: "Unknown Author"
  defp normalize_author(%{author: author}), do: author

  defp build_contributor_stat({author, author_commits}, total_commits) do
    author_analyses = Enum.map(author_commits, & &1.analysis)

    %{
      name: author,
      commit_count: length(author_commits),
      percentage: safe_percentage(length(author_commits), total_commits),
      most_common_type: get_most_common_type(author_analyses),
      avg_word_count: safe_average(Enum.map(author_analyses, & &1.word_count))
    }
  end

  # Safe math helper functions

  defp safe_average([]), do: 0
  defp safe_average(list), do: Float.round(Enum.sum(list) / length(list), 1)

  defp safe_max([]), do: 0
  defp safe_max(list), do: Enum.max(list)

  defp safe_min([]), do: 0
  defp safe_min(list), do: Enum.min(list)

  defp safe_percentage(_numerator, 0), do: 0
  defp safe_percentage(numerator, denominator), do: Float.round(numerator / denominator * 100, 1)
end
