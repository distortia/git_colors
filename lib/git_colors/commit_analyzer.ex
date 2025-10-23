defmodule GitColors.CommitAnalyzer do
  @moduledoc """
  A GenServer that uses Bumblebee to analyze git commit messages.

  This module loads a sentiment analysis model and provides functions to:
  - Classify commit types (feat, fix, docs, etc.)
  - Analyze sentiment (positive, neutral, negative)
  - Estimate complexity based on message content
  """

  use GenServer
  require Logger

  # Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def analyze_commit(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:analyze, message}, 10_000)
  end

  def ready?() do
    try do
      GenServer.call(__MODULE__, :ready?, 5_000)
    rescue
      _ ->
        false
    catch
      :exit, {:timeout, _} ->
        false

      :exit, {:noproc, _} ->
        false
    end
  end

  # GenServer Callbacks

  def init(_opts) do
    Logger.info("CommitAnalyzer: Starting to load models...")

    # Load models in a separate task to avoid blocking startup
    Task.start_link(fn -> load_models() end)

    {:ok, %{models_loaded: false, sentiment_serving: nil}}
  end

  def handle_call({:analyze, _message}, _from, %{models_loaded: false} = state) do
    {:reply, {:error, "Models not loaded yet"}, state}
  end

  def handle_call({:analyze, message}, _from, %{sentiment_serving: serving} = state) do
    analysis = perform_analysis(message, serving)
    {:reply, {:ok, analysis}, state}
  end

  def handle_call(:ready?, _from, %{models_loaded: loaded} = state) do
    {:reply, loaded, state}
  end

  def handle_info({:models_loaded, serving}, state) do
    Logger.info("CommitAnalyzer: Models loaded successfully!")
    {:noreply, %{state | models_loaded: true, sentiment_serving: serving}}
  end

  def handle_info({:model_load_error, error}, state) do
    Logger.error("CommitAnalyzer: Failed to load models: #{inspect(error)}")
    {:noreply, state}
  end

  # Private Functions

  defp load_models() do
    try do
      # Load a lightweight sentiment analysis model
      {:ok, model_info} =
        Bumblebee.load_model({:hf, "cardiffnlp/twitter-roberta-base-sentiment-latest"})

      {:ok, tokenizer} =
        Bumblebee.load_tokenizer({:hf, "cardiffnlp/twitter-roberta-base-sentiment-latest"})

      # Create a serving for efficient inference
      serving =
        Bumblebee.Text.text_classification(model_info, tokenizer,
          compile: [batch_size: 1, sequence_length: 128],
          defn_options: [compiler: EXLA]
        )

      send(self(), {:models_loaded, serving})
    rescue
      error ->
        Logger.error(
          "Failed to load sentiment model, falling back to basic analysis: #{inspect(error)}"
        )

        send(self(), {:models_loaded, nil})
    end
  end

  defp perform_analysis(message, sentiment_serving) do
    %{
      type: classify_commit_type(message),
      sentiment: analyze_sentiment(message, sentiment_serving),
      complexity: estimate_complexity(message),
      word_count: word_count(message),
      has_breaking_change: has_breaking_change?(message),
      is_ai_generated: detect_ai_generated(message)
    }
  end

  defp classify_commit_type(message) do
    message_lower = String.downcase(message)

    cond do
      String.match?(message_lower, ~r/^(feat|feature)[\(\:]/) -> "feat"
      String.match?(message_lower, ~r/^fix[\(\:]/) -> "fix"
      String.match?(message_lower, ~r/^docs[\(\:]/) -> "docs"
      String.match?(message_lower, ~r/^style[\(\:]/) -> "style"
      String.match?(message_lower, ~r/^refactor[\(\:]/) -> "refactor"
      String.match?(message_lower, ~r/^test[\(\:]/) -> "test"
      String.match?(message_lower, ~r/^chore[\(\:]/) -> "chore"
      String.match?(message_lower, ~r/^perf[\(\:]/) -> "perf"
      String.match?(message_lower, ~r/^ci[\(\:]/) -> "ci"
      String.match?(message_lower, ~r/^build[\(\:]/) -> "build"
      String.match?(message_lower, ~r/^revert[\(\:]/) -> "revert"
      # Fallback analysis based on keywords
      String.contains?(message_lower, ["add", "implement", "create", "new"]) -> "feat"
      String.contains?(message_lower, ["fix", "bug", "issue", "error"]) -> "fix"
      String.contains?(message_lower, ["update", "change", "modify"]) -> "chore"
      String.contains?(message_lower, ["remove", "delete", "clean"]) -> "chore"
      String.contains?(message_lower, ["test", "spec"]) -> "test"
      String.contains?(message_lower, ["doc", "readme", "comment"]) -> "docs"
      true -> "other"
    end
  end

  defp analyze_sentiment(message, nil) do
    # Fallback sentiment analysis without AI model
    message_lower = String.downcase(message)

    positive_words = ["add", "improve", "enhance", "optimize", "better", "new", "feature"]
    negative_words = ["fix", "bug", "error", "issue", "problem", "fail", "broken"]

    positive_count = Enum.count(positive_words, &String.contains?(message_lower, &1))
    negative_count = Enum.count(negative_words, &String.contains?(message_lower, &1))

    cond do
      positive_count > negative_count -> "positive"
      negative_count > positive_count -> "negative"
      true -> "neutral"
    end
  end

  defp analyze_sentiment(message, serving) do
    try do
      case Nx.Serving.batched_run(serving, message) do
        %{predictions: [%{label: label, score: score}]} when score > 0.6 ->
          case label do
            "LABEL_0" -> "negative"
            "LABEL_1" -> "neutral"
            "LABEL_2" -> "positive"
            _ -> "neutral"
          end

        _ ->
          # Fallback to keyword-based analysis if confidence is low
          analyze_sentiment(message, nil)
      end
    rescue
      _ ->
        analyze_sentiment(message, nil)
    end
  end

  defp estimate_complexity(message) do
    word_count = word_count(message)

    # Check for complexity indicators
    complexity_indicators = [
      String.contains?(message, ["refactor", "restructure", "rewrite"]),
      String.contains?(message, ["breaking change", "BREAKING CHANGE"]),
      String.contains?(message, ["migrate", "migration"]),
      String.contains?(message, ["database", "schema"]),
      String.contains?(message, ["api", "endpoint", "route"]),
      word_count > 10
    ]

    complexity_score = Enum.count(complexity_indicators, & &1)

    cond do
      complexity_score >= 3 -> "high"
      complexity_score >= 1 -> "medium"
      true -> "low"
    end
  end

  defp word_count(message) do
    message
    |> String.split()
    |> length()
  end

  defp has_breaking_change?(message) do
    message_lower = String.downcase(message)

    String.contains?(message_lower, ["breaking change", "breaking:", "!:"]) or
      String.contains?(message, ["BREAKING CHANGE", "BREAKING:"])
  end

  defp detect_ai_generated(message) do
    # Various heuristics to detect AI-generated commit messages
    message_lower = String.downcase(message)
    word_count = word_count(message)

    # Start with base score
    initial_score = 0

    # 1. AI-specific phrases and patterns
    ai_phrases = [
      "this commit",
      "this change",
      "this update",
      "this modification",
      "this implementation",
      "in order to",
      "for the purpose of",
      "to ensure that",
      "with the aim of",
      "comprehensive",
      "substantial",
      "significant enhancement",
      "improved functionality",
      "enhanced performance",
      "optimized implementation",
      "streamlined process",
      "refined approach",
      "robust solution",
      "seamless integration",
      "efficient handling"
    ]

    ai_phrase_count = Enum.count(ai_phrases, &String.contains?(message_lower, &1))
    score_after_phrases = initial_score + ai_phrase_count * 2

    # 2. Overly formal language for simple changes
    formal_words = [
      "implement",
      "facilitate",
      "utilize",
      "demonstrate",
      "incorporate",
      "establish",
      "maintain",
      "ensure",
      "provide",
      "enhance",
      "optimize",
      "streamline",
      "improve",
      "refine",
      "comprehensive",
      "substantial"
    ]

    simple_change_indicators = ["fix", "add", "remove", "update", "change"]

    score_after_formal =
      if Enum.any?(simple_change_indicators, &String.contains?(message_lower, &1)) do
        formal_count = Enum.count(formal_words, &String.contains?(message_lower, &1))
        # Higher penalty for formal words in simple changes
        score_after_phrases + formal_count * 3
      else
        score_after_phrases
      end

    # 3. Perfect grammar with no abbreviations or common developer shortcuts
    common_abbreviations = ["fix:", "feat:", "docs:", "chore:", "wip", "tmp", "temp", "refactor:"]
    has_abbreviations = Enum.any?(common_abbreviations, &String.contains?(message_lower, &1))

    # AI tends to avoid abbreviations
    score_after_abbrev =
      unless has_abbreviations do
        score_after_formal + 1
      else
        score_after_formal
      end

    # 4. Length inconsistencies - too verbose for simple changes
    score_after_length =
      if word_count > 8 do
        # Check if it's a simple change with too many words
        simple_changes = ["fix", "add", "remove", "delete", "update"]

        if Enum.any?(simple_changes, &String.contains?(message_lower, &1)) do
          score_after_abbrev + 2
        else
          score_after_abbrev
        end
      else
        score_after_abbrev
      end

    # 5. AI-like sentence structure patterns
    ai_sentence_patterns = [
      ~r/^(add|implement|create|establish|introduce)\s+.*\s+(to|for)\s+/,
      ~r/^(update|modify|change|refine)\s+.*\s+(to|for)\s+(improve|enhance|optimize)/,
      ~r/this\s+(commit|change|update)\s+(adds|implements|creates|establishes)/
    ]

    pattern_matches = Enum.count(ai_sentence_patterns, &Regex.match?(&1, message_lower))
    score_after_patterns = score_after_length + pattern_matches * 2

    # 6. Repetitive or templated structure
    score_after_template =
      if String.contains?(message_lower, [
           "add support for",
           "implement support for",
           "update support for"
         ]) do
        score_after_patterns + 2
      else
        score_after_patterns
      end

    # 7. Perfect capitalization and punctuation (no casual style)
    # AI often uses perfect sentence case
    final_score =
      if String.match?(message, ~r/^[A-Z][a-z].*[\.!]$/) and word_count > 3 do
        score_after_template + 1
      else
        score_after_template
      end

    # Convert score to probability
    # Threshold: score >= 6 suggests likely AI-generated
    cond do
      # Very likely AI
      final_score >= 8 -> "highly_likely"
      # Probably AI
      final_score >= 5 -> "likely"
      # Could be AI
      final_score >= 3 -> "possible"
      # Probably human
      true -> "unlikely"
    end
  end
end
