defmodule GitColorsWeb.ColorLiveAnalysisTest do
  use ExUnit.Case, async: true

  describe "basic commit analysis" do
    test "classifies different commit types correctly" do
      test_cases = [
        {"feat: add new user authentication", "feat"},
        {"fix: resolve password validation bug", "fix"},
        {"docs: update API documentation", "docs"},
        {"test: add user authentication tests", "test"},
        {"refactor: improve code structure", "refactor"},
        {"chore: update dependencies", "chore"},
        {"revert: undo previous changes", "revert"},
        {"Revert \"add broken feature\"", "revert"},
        {"This reverts commit abc123", "revert"},
        {"add tests", "feat"},
        {"fix issues", "fix"},
        {"update agents.md", "chore"},
        {"remove page controller", "chore"},
        {"initial commit lol", "other"}
      ]

      for {message, expected_type} <- test_cases do
        # Use the private function through a public interface
        analysis = test_analysis(message)

        assert analysis.type == expected_type,
               "Expected #{expected_type} for '#{message}', got #{analysis.type}"
      end
    end

    test "analyzes sentiment correctly" do
      positive_messages = [
        "add new feature",
        "improve performance",
        "enhance user experience",
        "implement OAuth"
      ]

      negative_messages = [
        "fix critical bug",
        "remove deprecated code",
        "fix broken tests",
        "delete unused files"
      ]

      for message <- positive_messages do
        analysis = test_analysis(message)

        assert analysis.sentiment == "positive",
               "Expected positive sentiment for '#{message}', got #{analysis.sentiment}"
      end

      for message <- negative_messages do
        analysis = test_analysis(message)

        assert analysis.sentiment == "negative",
               "Expected negative sentiment for '#{message}', got #{analysis.sentiment}"
      end
    end

    test "estimates complexity correctly" do
      simple_messages = ["fix typo", "update readme", "add test"]

      complex_messages = [
        "refactor entire authentication system",
        "BREAKING CHANGE: remove deprecated API",
        "migrate database schema with new user model and relationships"
      ]

      for message <- simple_messages do
        analysis = test_analysis(message)

        assert analysis.complexity == "low",
               "Expected low complexity for '#{message}', got #{analysis.complexity}"
      end

      for message <- complex_messages do
        analysis = test_analysis(message)

        assert analysis.complexity in ["medium", "high"],
               "Expected medium/high complexity for '#{message}', got #{analysis.complexity}"
      end
    end

    test "detects breaking changes" do
      breaking_messages = [
        "feat!: change API response format",
        "BREAKING CHANGE: remove user endpoint",
        "refactor: BREAKING: update authentication"
      ]

      normal_messages = [
        "feat: add new endpoint",
        "fix: resolve validation issue",
        "docs: update API examples"
      ]

      for message <- breaking_messages do
        analysis = test_analysis(message)

        assert analysis.has_breaking_change,
               "Expected breaking change detection for '#{message}'"
      end

      for message <- normal_messages do
        analysis = test_analysis(message)

        refute analysis.has_breaking_change,
               "Expected no breaking change for '#{message}'"
      end
    end

    test "counts words correctly" do
      test_cases = [
        {"fix", 1},
        {"fix bug", 2},
        {"add new user authentication feature", 5},
        {"", 0}
      ]

      for {message, expected_count} <- test_cases do
        analysis = test_analysis(message)

        assert analysis.word_count == expected_count,
               "Expected #{expected_count} words for '#{message}', got #{analysis.word_count}"
      end
    end

    test "calculates word count statistics correctly" do
      # Create mock commits with different word counts
      commits = [
        %{
          hash: "abc123",
          color: "ff0000",
          message: "fix",
          analysis: %{
            type: "fix",
            sentiment: "negative",
            complexity: "low",
            word_count: 1,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "def456",
          color: "00ff00",
          message: "add new feature",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "medium",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "ghi789",
          color: "0000ff",
          message: "refactor authentication system with new OAuth implementation",
          analysis: %{
            type: "refactor",
            sentiment: "neutral",
            complexity: "high",
            word_count: 8,
            has_breaking_change: false,
            is_ai_generated: "possible"
          }
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      assert stats.word_count_stats.average == 4.0
      assert stats.word_count_stats.min == 1
      assert stats.word_count_stats.max == 8
      assert stats.word_count_stats.total_words == 12
    end

    test "calculates complexity distribution correctly" do
      # Create mock commits with different complexity levels
      commits = [
        %{
          hash: "abc123",
          color: "ff0000",
          message: "fix typo",
          analysis: %{
            type: "fix",
            sentiment: "negative",
            complexity: "low",
            word_count: 2,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "def456",
          color: "00ff00",
          message: "fix another typo",
          analysis: %{
            type: "fix",
            sentiment: "negative",
            complexity: "low",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "ghi789",
          color: "0000ff",
          message: "refactor authentication system",
          analysis: %{
            type: "refactor",
            sentiment: "neutral",
            complexity: "high",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "jkl012",
          color: "ffff00",
          message: "add user validation",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "medium",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Check complexity distribution
      complexity_map = Enum.into(stats.complexity_distribution, %{})
      assert complexity_map["low"] == 2
      assert complexity_map["medium"] == 1
      assert complexity_map["high"] == 1

      # Check that complexity distribution is sorted by count (descending)
      [top_complexity | _] = stats.complexity_distribution
      assert elem(top_complexity, 0) == "low"
      assert elem(top_complexity, 1) == 2
    end

    test "detects AI-generated commit messages" do
      ai_messages = [
        "This commit implements comprehensive user authentication functionality",
        "Add support for enhanced email validation to ensure optimal user experience",
        "Implement robust error handling mechanisms for improved system reliability"
      ]

      human_messages = [
        "fix typo in readme",
        "add tests",
        "wip: working on auth",
        "feat: new user model",
        "quick fix for bug #123",
        "remove tmp files"
      ]

      for message <- ai_messages do
        analysis = test_analysis(message)

        assert analysis.is_ai_generated in ["possible", "likely", "highly_likely"],
               "Expected AI detection for '#{message}', got #{analysis.is_ai_generated}"
      end

      for message <- human_messages do
        analysis = test_analysis(message)

        assert analysis.is_ai_generated in ["unlikely", "possible"],
               "Expected human detection for '#{message}', got #{analysis.is_ai_generated}"
      end
    end

    test "calculates AI generation statistics correctly" do
      # Create mock commits with different AI likelihood levels
      commits = [
        %{
          hash: "abc123",
          color: "ff0000",
          message: "fix typo",
          analysis: %{
            type: "fix",
            sentiment: "negative",
            complexity: "low",
            word_count: 2,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "def456",
          color: "00ff00",
          message: "This commit implements comprehensive authentication functionality",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "high",
            word_count: 7,
            has_breaking_change: false,
            is_ai_generated: "highly_likely"
          }
        },
        %{
          hash: "ghi789",
          color: "0000ff",
          message: "Add support for enhanced user validation",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "medium",
            word_count: 6,
            has_breaking_change: false,
            is_ai_generated: "likely"
          }
        },
        %{
          hash: "jkl012",
          color: "ffff00",
          message: "add user validation",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "medium",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Check AI generation statistics
      # "likely" + "highly_likely"
      assert stats.ai_generation_stats.likely_ai_count == 2
      assert stats.ai_generation_stats.likely_ai_percentage == 50.0

      # Check AI distribution
      ai_distribution_map = Enum.into(stats.ai_generation_stats.distribution, %{})
      assert ai_distribution_map["unlikely"] == 2
      assert ai_distribution_map["likely"] == 1
      assert ai_distribution_map["highly_likely"] == 1
    end

    test "calculates revert statistics correctly" do
      # Create mock commits with some reverts
      commits = [
        %{
          hash: "abc123",
          color: "ff0000",
          message: "feat: add new feature",
          analysis: %{
            type: "feat",
            sentiment: "positive",
            complexity: "medium",
            word_count: 4,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "def456",
          color: "00ff00",
          message: "revert: undo previous commit",
          analysis: %{
            type: "revert",
            sentiment: "negative",
            complexity: "low",
            word_count: 4,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "ghi789",
          color: "0000ff",
          message: "fix: bug fix",
          analysis: %{
            type: "fix",
            sentiment: "negative",
            complexity: "low",
            word_count: 3,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        },
        %{
          hash: "jkl012",
          color: "ffff00",
          message: "Revert \"previous feature implementation\"",
          analysis: %{
            type: "revert",
            sentiment: "negative",
            complexity: "low",
            word_count: 4,
            has_breaking_change: false,
            is_ai_generated: "unlikely"
          }
        }
      ]

      stats = GitColorsWeb.ColorLive.get_commit_analysis_stats(commits)

      # Check revert statistics
      assert stats.revert_stats.count == 2
      assert stats.revert_stats.percentage == 50.0

      # Test with no reverts
      no_revert_commits = [
        %{
          hash: "abc123",
          color: "ff0000",
          message: "feat: add feature",
          analysis: %{type: "feat", sentiment: "positive", complexity: "low", word_count: 3, has_breaking_change: false, is_ai_generated: "unlikely"}
        }
      ]

      stats_no_reverts = GitColorsWeb.ColorLive.get_commit_analysis_stats(no_revert_commits)
      assert stats_no_reverts.revert_stats.count == 0
      assert stats_no_reverts.revert_stats.percentage == 0.0
    end
  end

  # Helper function to test private analysis functions
  defp test_analysis(message) do
    # We need to test this via the actual module - let's create a small wrapper
    GitColorsWeb.ColorLive.__test_perform_basic_analysis__(message)
  end
end
