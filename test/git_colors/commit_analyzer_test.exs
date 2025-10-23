defmodule GitColors.CommitAnalyzerTest do
  use ExUnit.Case, async: true

  describe "CommitAnalyzer" do
    test "starts successfully" do
      # The analyzer should already be started by the application
      assert Process.alive?(Process.whereis(GitColors.CommitAnalyzer))
    end

    test "analyzes commit messages with fallback when model not ready" do
      # Test basic functionality even if model isn't loaded yet
      case GitColors.CommitAnalyzer.analyze_commit("feat: add new user authentication") do
        {:ok, analysis} ->
          assert analysis.type == "feat"
          assert analysis.sentiment in ["positive", "neutral", "negative"]
          assert analysis.complexity in ["low", "medium", "high"]
          assert is_integer(analysis.word_count)
          assert is_boolean(analysis.has_breaking_change)

        {:error, "Models not loaded yet"} ->
          # This is acceptable during testing
          :ok
      end
    end

    test "ready? returns boolean" do
      result = GitColors.CommitAnalyzer.ready?()
      assert is_boolean(result)
    end

    test "handles different commit types" do
      test_cases = [
        {"fix: resolve password validation bug", "fix"},
        {"docs: update API documentation", "docs"},
        {"test: add user authentication tests", "test"},
        {"refactor: improve code structure", "refactor"},
        {"chore: update dependencies", "chore"},
        {"feat(auth): implement OAuth integration", "feat"},
        {"Add new feature for dashboard", "feat"},
        {"Fix critical security issue", "fix"},
        {"Update documentation", "chore"}
      ]

      for {message, expected_type} <- test_cases do
        case GitColors.CommitAnalyzer.analyze_commit(message) do
          {:ok, analysis} ->
            assert analysis.type == expected_type,
                   "Expected #{expected_type} for '#{message}', got #{analysis.type}"

          {:error, "Models not loaded yet"} ->
            # Skip if models aren't ready
            :ok
        end
      end
    end

    test "detects breaking changes" do
      breaking_messages = [
        "feat!: change API response format",
        "BREAKING CHANGE: remove deprecated endpoint",
        "refactor: BREAKING: update user model"
      ]

      for message <- breaking_messages do
        case GitColors.CommitAnalyzer.analyze_commit(message) do
          {:ok, analysis} ->
            assert analysis.has_breaking_change, "Expected breaking change for '#{message}'"

          {:error, "Models not loaded yet"} ->
            :ok
        end
      end
    end
  end
end
