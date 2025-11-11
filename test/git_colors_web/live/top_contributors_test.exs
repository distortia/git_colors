defmodule GitColorsWeb.TopContributorsTest do
  use ExUnit.Case, async: true

  describe "top contributors analysis" do
    test "calculates top contributors correctly" do
      # Create mock commits with different authors
      commits = [
        %{
          hash: "abc123", color: "ff0000", message: "feat: add feature", author: "Alice Johnson",
          analysis: %{type: "feat", sentiment: "positive", complexity: "medium", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        },
        %{
          hash: "def456", color: "00ff00", message: "fix: bug fix", author: "Alice Johnson",
          analysis: %{type: "fix", sentiment: "negative", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        },
        %{
          hash: "ghi789", color: "0000ff", message: "docs: update docs", author: "Bob Smith",
          analysis: %{type: "docs", sentiment: "neutral", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        },
        %{
          hash: "jkl012", color: "ffff00", message: "feat: new feature", author: "Alice Johnson",
          analysis: %{type: "feat", sentiment: "positive", complexity: "high", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        },
        %{
          hash: "mno345", color: "ff00ff", message: "chore: update deps", author: "Charlie Davis",
          analysis: %{type: "chore", sentiment: "neutral", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Check contributor statistics
      assert length(stats.contributor_stats) == 3

      # Alice should be top contributor with 3 commits (60%)
      top_contributor = List.first(stats.contributor_stats)
      assert top_contributor.name == "Alice Johnson"
      assert top_contributor.commit_count == 3
      assert top_contributor.percentage == 60.0
      assert top_contributor.most_common_type == "feat"
      assert top_contributor.avg_word_count == 3.0

      # Bob should be second with 1 commit (20%)
      second_contributor = Enum.at(stats.contributor_stats, 1)
      assert second_contributor.name == "Bob Smith"
      assert second_contributor.commit_count == 1
      assert second_contributor.percentage == 20.0
      assert second_contributor.most_common_type == "docs"

      # Charlie should be third with 1 commit (20%)
      third_contributor = Enum.at(stats.contributor_stats, 2)
      assert third_contributor.name == "Charlie Davis"
      assert third_contributor.commit_count == 1
      assert third_contributor.percentage == 20.0
      assert third_contributor.most_common_type == "chore"
    end

    test "handles empty commits gracefully" do
      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats([])

      assert stats.contributor_stats == []
    end

    test "limits to top 5 contributors" do
      # Create commits with 7 different authors
      commits =
        for i <- 1..7 do
          %{
            hash: "abc#{i}23", color: "ff000#{i}", message: "feat: feature #{i}", author: "Author #{i}",
            analysis: %{type: "feat", sentiment: "positive", complexity: "low", word_count: 2, has_breaking_change: false, is_ai_generated: "unlikely"}
          }
        end

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Should only return top 5
      assert length(stats.contributor_stats) == 5
    end

    test "handles missing author gracefully" do
      commits = [
        %{
          hash: "abc123", color: "ff0000", message: "feat: add feature", author: "",
          analysis: %{type: "feat", sentiment: "positive", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        },
        %{
          hash: "def456", color: "00ff00", message: "fix: bug fix", author: nil,
          analysis: %{type: "fix", sentiment: "negative", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Should group empty/nil authors together as "Unknown Author"
      assert length(stats.contributor_stats) == 1

      # Check that we can handle nil/empty authors
      contributor = List.first(stats.contributor_stats)
      assert contributor.name == "Unknown Author"
      assert contributor.commit_count == 2
      assert contributor.percentage == 100.0
    end
  end
end
