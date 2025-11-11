defmodule GitColorsWeb.ColorLive do
  use GitColorsWeb, :live_view
  require Logger
  alias GitColors.Analytics

  @cache_table :git_colors_cache
  @cache_ttl_seconds 30

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900">
      <!-- Mobile Header -->
      <div class="lg:hidden bg-gray-800 border-b border-gray-700 p-4">
        <div class="flex items-center justify-between">
          <h1 class="text-lg font-bold text-gray-100">Git Colors</h1>
          <button
            phx-click="toggle_mobile_sidebar"
            class="p-2 text-gray-400 hover:text-gray-200 transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16"
              >
              </path>
            </svg>
          </button>
        </div>
      </div>

      <div class="flex flex-col lg:flex-row">
        <!-- Sidebar -->
        <div class={"#{if @show_mobile_sidebar, do: "block", else: "hidden"} lg:block w-full lg:w-80 bg-gray-800 shadow-lg border-r border-gray-700"}>
          <div class="p-4 lg:p-6">
            <h2 class="text-xl font-bold text-gray-100 mb-6 hidden lg:block">Repository Analysis</h2>

    <!-- Form Section -->
            <div class="mb-6 lg:mb-8">
              <.form for={@form} id="directory-form" phx-submit="link_directory" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-300 mb-2">
                    Link to a local directory
                  </label>
                  <.input
                    field={@form[:directory_path]}
                    type="text"
                    placeholder="e.g., /Users/username/my-project"
                    class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-gray-100 placeholder-gray-400 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-300 mb-2">
                    Number of commits
                  </label>
                  <.input
                    field={@form[:commit_count]}
                    type="select"
                    options={[
                      {"100 commits", "100"},
                      {"500 commits", "500"},
                      {"1000 commits", "1000"},
                      {"10,000 commits", "10000"},
                      {"All commits", "all"}
                    ]}
                    class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-gray-100 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <button
                  type="submit"
                  disabled={@loading}
                  class={[
                    "w-full font-medium py-2 px-4 rounded-md transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-800",
                    if(@loading,
                      do: "bg-gray-600 cursor-not-allowed text-gray-300",
                      else: "bg-blue-600 hover:bg-blue-700 text-white"
                    )
                  ]}
                >
                  <%= if @loading do %>
                    <div class="flex items-center justify-center">
                      <svg
                        class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        >
                        </circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        >
                        </path>
                      </svg>
                      Loading...
                    </div>
                  <% else %>
                    Submit
                  <% end %>
                </button>

    <!-- Disclaimer -->
                <div class="mt-3 p-3 bg-yellow-900 border border-yellow-700 rounded-md">
                  <p class="text-yellow-200 text-xs">
                    <span class="font-medium">⚠️ Large Repositories:</span>
                    Repositories with 10k+ commits may take time to process.
                    Consider using smaller commit counts for faster results or testing.
                  </p>
                </div>
              </.form>
            </div>

    <!-- Repository Info -->
            <%= if @linked_directory do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Repository Info</h3>
                <div class="bg-green-900 border border-green-700 rounded-md p-3 mb-4">
                  <p class="text-green-200 text-sm">
                    <span class="font-medium">Directory:</span>
                    <br />
                    <span class="font-mono text-xs break-all">{@linked_directory}</span>
                  </p>
                </div>

                <%= if @commit_colors != [] do %>
                  <div class="space-y-3">
                    <div class="bg-blue-900 border border-blue-700 rounded-md p-3">
                      <p class="text-blue-200 text-sm">
                        <span class="font-medium">Total Commits:</span> {length(@commit_colors)}
                      </p>
                    </div>

                    <div class="bg-purple-900 border border-purple-700 rounded-md p-3">
                      <p class="text-purple-200 text-sm">
                        <span class="font-medium">Unique Colors:</span> {@commit_colors
                        |> Analytics.extract_colors()
                        |> Enum.uniq()
                        |> length()}
                      </p>
                    </div>

                    <div class="bg-orange-900 border border-orange-700 rounded-md p-3">
                      <p class="text-orange-200 text-sm">
                        <span class="font-medium">Coverage:</span> {@commit_count || "100"} commits
                      </p>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>

    <!-- Selected Color Info -->
            <%= if @selected_color do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Selected Color</h3>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <div class="flex items-center space-x-3 mb-3">
                    <div
                      class="w-12 h-12 rounded-lg border-2 border-gray-500"
                      style={"background-color: ##{@selected_color}"}
                    >
                    </div>
                    <div>
                      <p class="font-mono text-lg font-bold text-gray-100">#{@selected_color}</p>
                      <p class="text-sm text-gray-400">Hex Color</p>
                    </div>
                  </div>

    <!-- Color Analysis -->
                  <div class="space-y-2 text-sm">
                    <div class="flex justify-between">
                      <span class="text-gray-400">RGB:</span>
                      <span class="font-mono text-gray-200">{hex_to_rgb(@selected_color)}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-400">Brightness:</span>
                      <span class="text-gray-200">{get_brightness(@selected_color)}%</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-400">Analysis:</span>
                      <a
                        href={"https://www.colorhexa.com/#{@selected_color}"}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-blue-400 hover:text-blue-300 underline transition-colors"
                      >
                        View on ColorHexa ↗
                      </a>
                    </div>
                  </div>

    <!-- Commit Information -->
                  <%= if @commit_colors != [] do %>
                    <% matching_commits = get_commits_for_color(@commit_colors, @selected_color) %>
                    <%= if length(matching_commits) > 0 do %>
                      <div class="mt-4 pt-4 border-t border-gray-600">
                        <h4 class="text-sm font-semibold text-gray-100 mb-3">
                          Commits with this color ({length(matching_commits)})
                        </h4>
                        <div class="space-y-2 max-h-48 overflow-y-auto">
                          <%= for commit <- Enum.take(matching_commits, 10) do %>
                            <div class="bg-gray-800 rounded p-2 text-xs">
                              <div class="flex justify-between items-start mb-1">
                                <span class="font-mono text-gray-300">
                                  #{String.slice(commit.hash, 0, 7)}
                                </span>
                                <span class="text-gray-500">{format_commit_date(commit.date)}</span>
                              </div>
                              <p class="text-gray-200 line-clamp-2">{commit.message}</p>
                              <div class="flex justify-between items-center mt-1">
                                <span class="px-1.5 py-0.5 text-xs bg-blue-800 text-blue-200 rounded">
                                  {commit.analysis.type}
                                </span>
                                <span class="text-gray-500">{commit.analysis.word_count} words</span>
                              </div>
                            </div>
                          <% end %>
                          <%= if length(matching_commits) > 10 do %>
                            <div class="text-center text-gray-500 text-xs pt-2">
                              ... and {length(matching_commits) - 10} more commits
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>

    <!-- Color Statistics -->
            <%= if @commit_colors != [] && length(@commit_colors) > 10 do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Color Statistics</h3>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <div class="space-y-2 text-sm">
                    <%= if Float.round(length(Enum.uniq(Analytics.extract_colors(@commit_colors))) / length(@commit_colors) * 100, 3) != 100.0 do %>
                      <div class="flex justify-between">
                        <span class="text-gray-400">Most Common:</span>
                        <div class="flex items-center space-x-2">
                          <div
                            class="w-4 h-4 rounded border border-gray-500"
                            style={"background-color: ##{Analytics.get_most_common_color(@commit_colors)}"}
                          >
                          </div>
                          <span class="font-mono text-gray-200">
                            #{Analytics.get_most_common_color(@commit_colors)}
                          </span>
                        </div>
                      </div>
                    <% end %>
                    <div class="flex justify-between">
                      <span class="text-gray-400">Diversity:</span>
                      <span class="text-gray-200">
                        {Float.round(
                          length(Enum.uniq(Analytics.extract_colors(@commit_colors))) /
                            length(@commit_colors) *
                            100,
                          3
                        )}%
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

    <!-- Commit Analysis -->
            <%= if @commit_colors != [] && length(@commit_colors) > 5 do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Commit Analysis</h3>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <% analysis_stats = Analytics.get_commit_analysis_stats(@commit_colors)
                  [top_type | _] = analysis_stats.type_distribution
                  [top_sentiment | _] = analysis_stats.sentiment_distribution
                  [top_complexity | _] = analysis_stats.complexity_distribution %>
                  <div class="space-y-3 text-sm">
                    <div class="bg-blue-800 bg-opacity-50 rounded p-2">
                      <div class="flex justify-between items-center mb-1">
                        <span class="text-blue-200 font-medium text-xs">Most Common:</span>
                        <span class="text-blue-100 font-mono text-xs px-1.5 py-0.5 bg-blue-900 rounded">
                          {elem(top_type, 0)}
                        </span>
                      </div>
                      <div class="text-xs text-blue-300">
                        {elem(top_type, 1)} commits ({Float.round(
                          elem(top_type, 1) / analysis_stats.total_commits * 100,
                          1
                        )}%)
                      </div>
                      <div class="text-xs text-blue-400 mt-1 italic">
                        Types of changes: feat, fix, docs, refactor, etc.
                      </div>
                    </div>

                    <div class="bg-green-800 bg-opacity-50 rounded p-2">
                      <div class="flex justify-between items-center mb-1">
                        <span class="text-green-200 font-medium text-xs">Sentiment:</span>
                        <span class="text-green-100 font-mono text-xs px-1.5 py-0.5 bg-green-900 rounded">
                          {elem(top_sentiment, 0)}
                        </span>
                      </div>
                      <div class="text-xs text-green-300">
                        {elem(top_sentiment, 1)} commits ({Float.round(
                          elem(top_sentiment, 1) / analysis_stats.total_commits * 100,
                          1
                        )}%)
                      </div>
                      <div class="text-xs text-green-400 mt-1 italic">
                        Emotional tone: positive, neutral, or negative
                      </div>
                    </div>

                    <div class="bg-yellow-800 bg-opacity-50 rounded p-2">
                      <div class="flex justify-between items-center mb-1">
                        <span class="text-yellow-200 font-medium text-xs">Word Count:</span>
                        <span class="text-yellow-100 font-mono text-xs px-1.5 py-0.5 bg-yellow-900 rounded">
                          {analysis_stats.word_count_stats.average} avg
                        </span>
                      </div>
                      <div class="text-xs text-yellow-300">
                        {analysis_stats.word_count_stats.total_words} total words • {analysis_stats.word_count_stats.min}-{analysis_stats.word_count_stats.max} range
                      </div>
                      <div class="text-xs text-yellow-400 mt-1 italic">
                        Message verbosity and communication patterns
                      </div>
                    </div>

                    <div class="bg-indigo-800 bg-opacity-50 rounded p-2">
                      <div class="flex justify-between items-center mb-1">
                        <span class="text-indigo-200 font-medium text-xs">Complexity:</span>
                        <span class="text-indigo-100 font-mono text-xs px-1.5 py-0.5 bg-indigo-900 rounded">
                          {elem(top_complexity, 0)}
                        </span>
                      </div>
                      <div class="text-xs text-indigo-300">
                        {elem(top_complexity, 1)} commits ({Float.round(
                          elem(top_complexity, 1) / analysis_stats.total_commits * 100,
                          1
                        )}%)
                      </div>
                      <div class="text-xs text-indigo-400 mt-1 italic">
                        Technical scope: low, medium, or high complexity
                      </div>
                    </div>

                    <div class="bg-purple-800 bg-opacity-50 rounded p-2">
                      <div class="flex justify-between items-center mb-1">
                        <span class="text-purple-200 font-medium text-xs">AI Detection:</span>
                        <span class="text-purple-100 font-mono text-xs px-1.5 py-0.5 bg-purple-900 rounded">
                          {analysis_stats.ai_generation_stats.likely_ai_percentage}%
                        </span>
                      </div>
                      <div class="text-xs text-purple-300">
                        {analysis_stats.ai_generation_stats.likely_ai_count} of {analysis_stats.total_commits} likely AI-written
                      </div>
                      <div class="text-xs text-purple-400 mt-1 italic">
                        Identifies potentially AI-generated commit messages
                      </div>
                    </div>

                    <%= if analysis_stats.breaking_changes > 0 do %>
                      <div class="bg-red-800 bg-opacity-50 rounded p-2">
                        <div class="flex justify-between items-center mb-1">
                          <span class="text-red-200 font-medium text-xs">Breaking Changes:</span>
                          <span class="text-red-100 font-mono text-xs px-1.5 py-0.5 bg-red-900 rounded">
                            {analysis_stats.breaking_changes}
                          </span>
                        </div>
                        <div class="text-xs text-red-300">
                          {Float.round(
                            analysis_stats.breaking_changes / analysis_stats.total_commits * 100,
                            1
                          )}% of commits
                        </div>
                        <div class="text-xs text-red-400 mt-1 italic">
                          Changes that break backward compatibility
                        </div>
                      </div>
                    <% end %>

                    <%= if analysis_stats.revert_stats.count > 0 do %>
                      <div class="bg-orange-800 bg-opacity-50 rounded p-2">
                        <div class="flex justify-between items-center mb-1">
                          <span class="text-orange-200 font-medium text-xs">Reverts:</span>
                          <span class="text-orange-100 font-mono text-xs px-1.5 py-0.5 bg-orange-900 rounded">
                            {analysis_stats.revert_stats.count}
                          </span>
                        </div>
                        <div class="text-xs text-orange-300">
                          {analysis_stats.revert_stats.percentage}% of commits
                        </div>
                        <div class="text-xs text-orange-400 mt-1 italic">
                          Commits that undo previous changes
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>

    <!-- Top Contributors -->
            <%= if @commit_colors != [] && length(@commit_colors) > 1 do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Top Contributors</h3>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <% analysis_stats = Analytics.get_commit_analysis_stats(@commit_colors) %>
                  <%= if length(analysis_stats.contributor_stats) > 0 do %>
                    <div class="space-y-3">
                      <%= for {contributor, index} <- Enum.with_index(analysis_stats.contributor_stats, 1) do %>
                        <div class="bg-gray-600 bg-opacity-50 rounded p-3 border border-gray-500">
                          <div class="flex items-center justify-between mb-2">
                            <div class="flex items-center space-x-3">
                              <div class="flex-shrink-0">
                                <%= if index <= 3 do %>
                                  <div class="w-8 h-8 flex items-center justify-center">
                                    <.icon name="hero-trophy" class={"w-7 h-7 #{case index do
                                      1 -> "text-yellow-400"  # Gold
                                      2 -> "text-gray-300"    # Silver
                                      3 -> "text-orange-600"  # Bronze
                                    end}"} />
                                  </div>
                                <% else %>
                                  <div class="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center text-gray-300 font-bold text-sm">
                                    {index}
                                  </div>
                                <% end %>
                              </div>
                              <div>
                                <h4 class="text-gray-100 font-medium text-sm">
                                  {contributor.name || "Unknown"}
                                </h4>
                                <div class="flex items-center space-x-4 text-xs text-gray-400">
                                  <span>{contributor.commit_count} commits</span>
                                  <span>{contributor.percentage}% of total</span>
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="text-xs text-gray-300">
                                <span class="inline-block px-2 py-1 bg-blue-800 text-blue-200 rounded text-xs">
                                  {contributor.most_common_type}
                                </span>
                              </div>
                              <div class="text-xs text-gray-400 mt-1">
                                {contributor.avg_word_count} avg words
                              </div>
                            </div>
                          </div>
                          <!-- Progress bar showing contribution percentage -->
                          <div class="w-full bg-gray-800 rounded-full h-2">
                            <div
                              class="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full transition-all duration-300"
                              style={"width: #{contributor.percentage}%"}
                            >
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <p class="text-gray-400 text-sm text-center py-2">
                      No contributor data available
                    </p>
                  <% end %>
                </div>
              </div>
            <% end %>

    <!-- Commit Timeline -->
            <%= if @commit_colors != [] do %>
              <div class="mb-6">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="text-lg font-semibold text-gray-100">Commit Timeline</h3>
                  <button
                    phx-click="toggle_pixel_popover"
                    class="inline-flex items-center px-2 py-1 text-xs font-medium text-gray-300 bg-gray-600 hover:bg-gray-500 rounded border border-gray-500 transition-colors duration-200"
                  >
                    <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 8V4a1 1 0 011-1h4m0 0V1m0 2h2m0 0V1m0 2h2m0 0V1m0 2h2M6 4v4m6 6V4m6 6V4"
                      >
                      </path>
                    </svg>
                    Pixels
                  </button>
                </div>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <p class="text-xs text-gray-400 mb-3">
                    Each pixel represents one commit (newest to oldest)
                  </p>
                  <div class="flex flex-wrap gap-0">
                    <%= for {commit, _index} <- Enum.with_index(@commit_colors) do %>
                      <div
                        class="w-1 h-1"
                        style={"background-color: ##{commit.color}"}
                      >
                      </div>
                    <% end %>
                  </div>
                  <p class="text-xs text-gray-400 mt-3">
                    {length(@commit_colors)} commits displayed as pixels
                  </p>
                </div>
              </div>
            <% end %>

    <!-- Error Messages -->
            <%= if @error_message do %>
              <div class="mt-4 p-4 bg-red-900 border border-red-700 rounded-md">
                <p class="text-red-200 text-sm">
                  <span class="font-medium">Error:</span> {@error_message}
                </p>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Pixel Popover -->
        <%= if @show_pixel_popover && @commit_colors != [] do %>
          <div
            class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-2 lg:p-4"
            phx-click="toggle_pixel_popover"
          >
            <div
              class="bg-gray-800 border border-gray-600 rounded-lg shadow-xl w-full max-w-4xl h-[90vh] lg:h-[80vh] flex flex-col"
              phx-click="toggle_pixel_popover"
            >
              <div class="bg-gray-800 border-b border-gray-600 p-3 lg:p-4 flex items-center justify-between flex-shrink-0">
                <h3 class="text-base lg:text-lg font-semibold text-gray-100">
                  Commit Timeline - Pixel View
                </h3>
                <button
                  phx-click="toggle_pixel_popover"
                  class="text-gray-400 hover:text-gray-200 transition-colors p-1"
                >
                  <svg
                    class="w-5 h-5 lg:w-6 lg:h-6"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M6 18L18 6M6 6l12 12"
                    >
                    </path>
                  </svg>
                </button>
              </div>
              <div class="p-3 lg:p-6 overflow-y-auto flex-1">
                <div class="mb-4">
                  <p class="text-xs lg:text-sm text-gray-400 mb-2">
                    {length(@commit_colors)} commits visualized as pixels (newest to oldest, left to right)
                  </p>
                  <div class="bg-gray-700 p-2 lg:p-3 rounded border border-gray-600">
                    <div
                      class="grid gap-0"
                      style={"grid-template-columns: repeat(#{max(20, div(calculate_grid_columns(length(@commit_colors)), 2))}, minmax(0, 1fr))"}
                    >
                      <%= for {commit, index} <- Enum.with_index(@commit_colors) do %>
                        <div
                          class="h-1 w-full"
                          style={"background-color: ##{commit.color}"}
                          title={"#{commit.message} (##{commit.color}) - #{format_commit_date(commit.date)}"}
                        >
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="text-xs text-gray-500">
                  <p>Scroll to view all pixels • Click anywhere to close</p>
                </div>
              </div>
            </div>
          </div>
        <% end %>

    <!-- Main Content -->
        <div class="flex-1 p-4 lg:p-8 bg-gray-900">
          <div class="max-w-6xl mx-auto">
            <h1 class="text-2xl lg:text-3xl font-bold text-gray-100 mb-4 text-center">
              Git Commits to
              <%= for {letter, color} <- @title_colors do %>
                <span style={"color: ##{color}; transition: color 0.5s ease-in-out;"}>{letter}</span>
              <% end %>
            </h1>
            <p class="text-center text-gray-400 mb-6 lg:mb-8 text-sm lg:text-base">
              Each color box represents the first 6 characters of a commit hash from
              <%= if @commit_colors != [] do %>
                {if @commit_count == "all",
                  do: "all",
                  else: "the most recent #{@commit_count || "100"}"} commits.
              <% else %>
                your repository commits.
              <% end %>
            </p>
            <%= if @commit_colors != [] do %>
              <div class="bg-gray-800 rounded-lg shadow-md p-4 lg:p-6 border border-gray-700">
                <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-4 gap-2">
                  <h3 class="text-base lg:text-lg font-semibold text-gray-100">
                    Commit Colors ({length(@commit_colors)} commits)
                  </h3>
                  <div class="text-xs text-gray-500">
                    <p class="hidden sm:block">
                      Click any pixel to view color details in the sidebar
                    </p>
                    <p class="sm:hidden">Tap any color to view details</p>
                  </div>
                </div>
                <div class="grid grid-cols-8 sm:grid-cols-12 md:grid-cols-16 lg:grid-cols-20 gap-1 sm:gap-2">
                  <%= for {commit, index} <- Enum.with_index(@commit_colors, 1) do %>
                    <%= if rem(index, 1000) == 0 do %>
                      <div class="col-span-full flex items-center justify-center py-2">
                        <div class="flex items-center space-x-2 bg-gray-700 px-3 py-1 rounded-full">
                          <span class="text-xs font-medium text-gray-300">
                            {index} commits
                          </span>
                          <div class="w-2 h-2 bg-gray-500 rounded-full"></div>
                        </div>
                      </div>
                    <% end %>
                    <.tooltip
                      text={"#{commit.message} (##{commit.color}) - #{commit.analysis.type} - #{format_commit_date(commit.date)}"}
                      position="tooltip-top"
                    >
                      <div
                        class="w-6 h-6 sm:w-7 sm:h-7 lg:w-8 lg:h-8 rounded border border-gray-600 flex items-center justify-center text-xs font-mono cursor-pointer hover:scale-110 active:scale-95 transition-transform"
                        style={"background-color: ##{commit.color}"}
                        phx-click="show_color"
                        phx-value-color={commit.color}
                      >
                      </div>
                    </.tooltip>
                  <% end %>
                </div>

                <div class="flex justify-end mt-4">
                  <button
                    onclick="window.scrollTo({ top: 0, behavior: 'smooth' })"
                    class="inline-flex items-center px-3 py-2 text-xs sm:text-sm font-medium text-gray-300 bg-gray-700 border border-gray-600 rounded-md hover:bg-gray-600 hover:text-white transition-colors duration-200"
                  >
                    <svg
                      class="w-3 h-3 sm:w-4 sm:h-4 mr-1 sm:mr-2"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 10l7-7m0 0l7 7m-7-7v18"
                      >
                      </path>
                    </svg>
                    <span class="hidden sm:inline">Jump to Top</span>
                    <span class="sm:hidden">Top</span>
                  </button>
                </div>
              </div>
            <% else %>
              <div class="text-center py-12 lg:py-16">
                <div class="text-gray-500 mb-4">
                  <svg
                    class="w-12 h-12 lg:w-16 lg:h-16 mx-auto"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                    >
                    </path>
                  </svg>
                </div>
                <h3 class="text-lg lg:text-xl font-medium text-gray-200 mb-2">
                  No Repository Loaded
                </h3>
                <p class="text-gray-400 text-sm lg:text-base px-4">
                  <span class="hidden sm:inline">
                    Enter a directory path in the sidebar to visualize commit colors
                  </span>
                  <span class="sm:hidden">Tap the menu to enter a directory path</span>
                </p>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Floating Navigation Buttons -->
        <%= if @commit_colors != [] do %>
          <!-- Jump to Bottom Button -->
          <button
            onclick="window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })"
            class="fixed bottom-4 right-4 inline-flex items-center px-3 lg:px-4 py-2 lg:py-3 text-xs lg:text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 z-10"
          >
            <svg
              class="w-4 h-4 lg:w-5 lg:h-5 mr-1 lg:mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 14l-7 7m0 0l-7-7m7 7V3"
              >
              </path>
            </svg>
            <span class="hidden sm:inline">Jump to Bottom</span>
            <span class="sm:hidden">Bottom</span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Initialize cache table if it doesn't exist
    ensure_cache_table_exists()

    form = to_form(%{"commit_count" => "100"})

    # Start timer for color rotation (2 seconds interval)
    if connected?(socket) do
      Process.send_after(self(), :rotate_colors, 2000)
    end

    # Check CommitAnalyzer status safely
    analyzer_ready = GitColors.CommitAnalyzer.ready?()

    socket =
      socket
      |> assign(:form, form)
      |> assign(:linked_directory, nil)
      |> assign(:commit_colors, [])
      |> assign(:commit_count, nil)
      |> assign(:selected_color, nil)
      |> assign(:loading, false)
      |> assign(:error_message, nil)
      |> assign(:show_pixel_popover, false)
      |> assign(:show_mobile_sidebar, false)
      |> assign(:title_colors, generate_colorful_letters("COLORS"))
      |> assign(:analyzer_ready, analyzer_ready)

    {:ok, socket}
  end

  def handle_event("show_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, :selected_color, color)}
  end

  def handle_event("toggle_pixel_popover", _params, socket) do
    {:noreply, assign(socket, :show_pixel_popover, !socket.assigns.show_pixel_popover)}
  end

  def handle_event("toggle_mobile_sidebar", _params, socket) do
    {:noreply, assign(socket, :show_mobile_sidebar, !socket.assigns.show_mobile_sidebar)}
  end

  def handle_event(
        "link_directory",
        %{"directory_path" => directory_path, "commit_count" => commit_count},
        socket
      ) do
    # Set loading state and clear previous results
    socket =
      socket
      |> assign(:loading, true)
      # Close mobile sidebar when submitting
      |> assign(:show_mobile_sidebar, false)
      |> assign(:commit_colors, [])
      |> assign(:selected_color, nil)
      |> assign(:error_message, nil)
      |> assign(:show_pixel_popover, false)

    # For "all commits", ensure minimum loading feedback duration
    if commit_count == "all" do
      # Schedule the actual work after a brief delay to ensure loading state is visible
      Process.send_after(self(), {:load_commits, directory_path, commit_count}, 300)
    else
      send(self(), {:load_commits, directory_path, commit_count})
    end

    {:noreply, socket}
  end

  def handle_info({:load_commits, directory_path, commit_count}, socket) do
    # All commit counts (including 'all') use the same non-streaming approach
    case get_limited_commits(directory_path, commit_count) do
      {:ok, commits} ->
        socket =
          socket
          |> assign(:linked_directory, directory_path)
          |> assign(:commit_colors, commits)
          |> assign(:commit_count, commit_count)
          |> assign(:loading, false)

        {:noreply, socket}

      {:error, error} ->
        socket =
          socket
          |> assign(:linked_directory, nil)
          |> assign(:commit_colors, [])
          |> assign(:commit_count, nil)
          |> assign(:loading, false)
          |> assign(:error_message, "Error reading repository: #{error}")

        {:noreply, socket}
    end
  end

  def handle_info(:rotate_colors, socket) do
    # Generate new colors for the title
    new_title_colors = generate_colorful_letters("COLORS")

    # Also update analyzer status
    analyzer_ready = GitColors.CommitAnalyzer.ready?()

    # Schedule next rotation
    Process.send_after(self(), :rotate_colors, 2000)

    socket =
      socket
      |> assign(:title_colors, new_title_colors)
      |> assign(:analyzer_ready, analyzer_ready)

    {:noreply, socket}
  end

  defp get_limited_commits(repo_path, count) do
    if count == "all" do
      get_all_commits_with_cache(repo_path)
    else
      # For limited commits, don't use cache
      fetch_commits(repo_path, count)
    end
  end

  defp get_all_commits_with_cache(repo_path) do
    case get_cached_commits(repo_path) do
      {:ok, cached_colors} ->
        Logger.info("Git Colors: Using cached results for repo: #{repo_path}")
        {:ok, cached_colors}

      :cache_miss ->
        # Fetch and cache the results
        case fetch_and_cache_all_commits(repo_path) do
          {:ok, colors} -> {:ok, colors}
          {:error, error} -> {:error, error}
        end
    end
  end

  defp fetch_commits(repo_path, count) do
    git_args = build_git_args(repo_path, count)

    case git_cmd("git", git_args) do
      {output, 0} ->
        commits = parse_commit_output(output)
        {:ok, commits}

      {error, status} ->
        handle_git_error(repo_path, count, error, status)
    end
  end

  defp build_git_args(repo_path, count) do
    case count do
      "all" -> ["-C", repo_path, "log", "--format=%H|%s|%an|%ci"]
      _ -> ["-C", repo_path, "log", "--format=%H|%s|%an|%ci", "-#{count}"]
    end
  end

  defp parse_commit_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_commit_line/1)
    |> Enum.filter(& &1)
  end

  defp parse_commit_line(line) do
    case String.split(line, "|", parts: 4) do
      [hash, message, author, date] -> create_commit_entry(hash, message, author, date)
      [hash, message, author] -> create_commit_entry(hash, message, author, "")
      [hash, message] -> create_commit_entry(hash, message, "", "")
      [hash] -> create_commit_entry(hash, "", "", "")
    end
  end

  defp create_commit_entry(hash, message, author, date) do
    color = String.slice(hash, 0, 6)

    if String.length(color) == 6 do
      analysis = get_commit_analysis(message)

      %{
        hash: hash,
        color: color,
        message: message,
        author: author,
        date: date,
        analysis: analysis
      }
    else
      nil
    end
  end

  defp get_commit_analysis(message) do
    case GitColors.CommitAnalyzer.analyze_commit(message) do
      {:ok, analysis_data} -> analysis_data
      {:error, _} -> perform_basic_analysis(message)
    end
  end

  defp handle_git_error(repo_path, count, error, status) do
    error_msg =
      "Failed to get commits for repo #{repo_path} (count: #{count}): #{String.trim(error)} (status: #{status})"

    Logger.error("Git Colors: #{error_msg}")
    {:error, error_msg}
  end

  defp perform_basic_analysis(message) do
    %{
      type: classify_commit_type_basic(message),
      sentiment: analyze_sentiment_basic(message),
      complexity: estimate_complexity_basic(message),
      word_count: word_count_basic(message),
      has_breaking_change: has_breaking_change_basic?(message),
      is_ai_generated: detect_ai_generated_basic(message)
    }
  end

  defp classify_commit_type_basic(message) do
    message_lower = String.downcase(message)

    # First try conventional commit pattern matching
    case classify_conventional_commit_basic(message_lower) do
      nil -> classify_by_keywords_basic(message_lower)
      type -> type
    end
  end

  defp classify_conventional_commit_basic(message_lower) do
    # Define conventional commit patterns
    patterns = [
      {~r/^(feat|feature)[\(\:]/, "feat"},
      {~r/^fix[\(\:]/, "fix"},
      {~r/^docs[\(\:]/, "docs"},
      {~r/^style[\(\:]/, "style"},
      {~r/^refactor[\(\:]/, "refactor"},
      {~r/^test[\(\:]/, "test"},
      {~r/^chore[\(\:]/, "chore"},
      {~r/^perf[\(\:]/, "perf"},
      {~r/^ci[\(\:]/, "ci"},
      {~r/^build[\(\:]/, "build"},
      {~r/^revert[\(\:]/, "revert"}
    ]

    Enum.find_value(patterns, fn {pattern, type} ->
      if String.match?(message_lower, pattern), do: type
    end)
  end

  defp classify_by_keywords_basic(message_lower) do
    cond do
      String.contains?(message_lower, ["revert"]) -> "revert"
      String.contains?(message_lower, ["add", "implement", "create", "new"]) -> "feat"
      String.contains?(message_lower, ["fix", "bug", "issue", "error"]) -> "fix"
      String.contains?(message_lower, ["update", "change", "modify"]) -> "chore"
      String.contains?(message_lower, ["remove", "delete", "clean"]) -> "chore"
      String.contains?(message_lower, ["test", "spec"]) -> "test"
      String.contains?(message_lower, ["doc", "readme", "comment"]) -> "docs"
      true -> "other"
    end
  end

  defp analyze_sentiment_basic(message) do
    message_lower = String.downcase(message)

    positive_words = [
      "add",
      "improve",
      "enhance",
      "optimize",
      "better",
      "new",
      "feature",
      "upgrade",
      "implement"
    ]

    negative_words = [
      "fix",
      "bug",
      "error",
      "issue",
      "problem",
      "fail",
      "broken",
      "remove",
      "delete",
      "deprecated"
    ]

    positive_count = Enum.count(positive_words, &String.contains?(message_lower, &1))
    negative_count = Enum.count(negative_words, &String.contains?(message_lower, &1))

    cond do
      positive_count > negative_count -> "positive"
      negative_count > positive_count -> "negative"
      true -> "neutral"
    end
  end

  defp estimate_complexity_basic(message) do
    word_count = word_count_basic(message)

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

  defp word_count_basic(message) do
    message
    |> String.split()
    |> length()
  end

  defp has_breaking_change_basic?(message) do
    message_lower = String.downcase(message)

    String.contains?(message_lower, ["breaking change", "breaking:", "!:"]) or
      String.contains?(message, ["BREAKING CHANGE", "BREAKING:"])
  end

  defp detect_ai_generated_basic(message) do
    # Simplified version of AI detection for basic analysis
    message_lower = String.downcase(message)
    word_count = word_count_basic(message)

    initial_score = 0

    # Check for AI-like phrases
    ai_phrases = [
      "this commit",
      "this change",
      "this update",
      "in order to",
      "for the purpose of",
      "comprehensive",
      "substantial",
      "enhanced",
      "optimized",
      "streamlined"
    ]

    ai_phrase_count = Enum.count(ai_phrases, &String.contains?(message_lower, &1))
    score_after_phrases = initial_score + ai_phrase_count * 2

    # Check for overly formal language in simple changes
    score_after_formal =
      if String.contains?(message_lower, ["fix", "add", "remove"]) and word_count > 6 do
        formal_words = ["implement", "facilitate", "utilize", "establish", "enhance"]
        formal_count = Enum.count(formal_words, &String.contains?(message_lower, &1))
        score_after_phrases + formal_count * 2
      else
        score_after_phrases
      end

    # Check for AI sentence patterns
    final_score =
      if String.match?(message_lower, ~r/^(add|implement|create)\s+.*\s+(to|for)\s+/) do
        score_after_formal + 2
      else
        score_after_formal
      end

    # Convert to simple classification
    cond do
      final_score >= 6 -> "highly_likely"
      final_score >= 4 -> "likely"
      final_score >= 2 -> "possible"
      true -> "unlikely"
    end
  end

  defp git_cmd(command, args) do
    if Application.get_env(:git_colors, :test_mode, false) do
      # Return mock data in test mode
      mock_git_response(args)
    else
      System.cmd(command, args, stderr_to_stdout: true)
    end
  end

  defp mock_git_response(args) do
    # Check if this should simulate an error (for testing error handling)
    case args do
      ["-C", "/test/error/path" | _] ->
        {"fatal: not a git repository", 128}

      _ ->
        # Return some mock commit hashes with messages, authors, and dates for testing
        mock_commits = """
        abc123def456|Add new feature for user authentication|Alice Johnson|2025-10-24 10:30:00 +0000
        789abc012def|Fix bug in password validation|Bob Smith|2025-10-23 14:15:30 +0000
        345def678abc|Update documentation for API endpoints|Charlie Davis|2025-10-22 09:45:15 +0000
        """

        {mock_commits, 0}
    end
  end

  defp fetch_and_cache_all_commits(repo_path) do
    case fetch_commits(repo_path, "all") do
      {:ok, colors} ->
        cache_commits(repo_path, colors)
        Logger.info("Git Colors: Cached #{length(colors)} commits for repo: #{repo_path}")
        {:ok, colors}

      {:error, error} ->
        {:error, error}
    end
  end

  defp ensure_cache_table_exists do
    case :ets.whereis(@cache_table) do
      :undefined ->
        :ets.new(@cache_table, [:set, :public, :named_table])
        Logger.info("Git Colors: Created cache table")

      _ ->
        :ok
    end
  end

  defp get_cached_commits(repo_path) do
    ensure_cache_table_exists()
    current_time = System.system_time(:second)

    case :ets.lookup(@cache_table, repo_path) do
      [{^repo_path, colors, timestamp}] ->
        if current_time - timestamp <= @cache_ttl_seconds do
          {:ok, colors}
        else
          # Cache expired, remove it
          :ets.delete(@cache_table, repo_path)
          :cache_miss
        end

      [] ->
        :cache_miss
    end
  end

  defp cache_commits(repo_path, colors) do
    ensure_cache_table_exists()
    timestamp = System.system_time(:second)
    :ets.insert(@cache_table, {repo_path, colors, timestamp})
  end

  # Helper functions for color analysis
  def hex_to_rgb(hex_color) do
    {r, ""} = String.slice(hex_color, 0, 2) |> Integer.parse(16)
    {g, ""} = String.slice(hex_color, 2, 2) |> Integer.parse(16)
    {b, ""} = String.slice(hex_color, 4, 2) |> Integer.parse(16)
    "#{r}, #{g}, #{b}"
  end

  def get_brightness(hex_color) do
    {r, ""} = String.slice(hex_color, 0, 2) |> Integer.parse(16)
    {g, ""} = String.slice(hex_color, 2, 2) |> Integer.parse(16)
    {b, ""} = String.slice(hex_color, 4, 2) |> Integer.parse(16)

    # Calculate perceived brightness using the luminance formula
    brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255 * 100
    Float.round(brightness, 1)
  end

  defp format_commit_date(""), do: "Unknown date"
  defp format_commit_date(nil), do: "Unknown date"

  defp format_commit_date(date_string) when is_binary(date_string) do
    # Git %ci format: "2025-10-24 10:52:50 -0400"
    # Parse and format as MM/DD/YYYY (US format)
    case String.split(date_string, " ") do
      [date_part | _] ->
        case String.split(date_part, "-") do
          [year, month, day] ->
            "#{month}/#{day}/#{year}"

          _ ->
            # Return original date part if parsing fails
            date_part
        end

      _ ->
        # Just show first part if parsing fails
        String.slice(date_string, 0..10)
    end
  end

  def calculate_grid_columns(commit_count) do
    cond do
      commit_count <= 100 -> 10
      commit_count <= 500 -> 25
      commit_count <= 1000 -> 40
      commit_count <= 5000 -> 50
      commit_count <= 10_000 -> 60
      true -> 80
    end
  end

  defp generate_random_color do
    # Generate a random 6-character hex color with better brightness
    # Ensure colors are not too dark by setting minimum values
    # 55-255
    r = :rand.uniform(200) + 55
    # 55-255
    g = :rand.uniform(200) + 55
    # 55-255
    b = :rand.uniform(200) + 55

    [r, g, b]
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.map_join("", &String.pad_leading(&1, 2, "0"))
  end

  def get_commits_for_color(commits, color) do
    commits
    |> Enum.filter(&(&1.color == color))
    # Most recent first - ISO dates sort correctly as strings
    |> Enum.sort_by(& &1.date, :desc)
  end

  defp generate_colorful_letters(text) do
    text
    |> String.graphemes()
    |> Enum.map(fn letter ->
      color = generate_random_color()
      {letter, color}
    end)
  end

  # Test helper function (only available in test environment)
  if Mix.env() == :test do
    def __test_perform_basic_analysis__(message) do
      perform_basic_analysis(message)
    end
  end
end
