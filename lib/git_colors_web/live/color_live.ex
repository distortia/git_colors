defmodule GitColorsWeb.ColorLive do
  use GitColorsWeb, :live_view
  require Logger

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
                    Repositories with 100k+ commits may take time to process.
                    Consider using smaller commit counts for faster results.
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
                  </div>
                </div>
              </div>
            <% end %>

    <!-- Color Statistics -->
            <%= if @commit_colors != [] && length(@commit_colors) > 10 do %>
              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-100 mb-3">Color Statistics</h3>
                <div class="bg-gray-700 border border-gray-600 rounded-md p-4">
                  <div class="space-y-2 text-sm">
                    <%= if Float.round(length(Enum.uniq(@commit_colors)) / length(@commit_colors) * 100, 3) != 100.0 do %>
                      <div class="flex justify-between">
                        <span class="text-gray-400">Most Common:</span>
                        <div class="flex items-center space-x-2">
                          <div
                            class="w-4 h-4 rounded border border-gray-500"
                            style={"background-color: ##{get_most_common_color(@commit_colors)}"}
                          >
                          </div>
                          <span class="font-mono text-gray-200">
                            #{get_most_common_color(@commit_colors)}
                          </span>
                        </div>
                      </div>
                    <% end %>
                    <div class="flex justify-between">
                      <span class="text-gray-400">Diversity:</span>
                      <span class="text-gray-200">
                        {Float.round(
                          length(Enum.uniq(@commit_colors)) / length(@commit_colors) * 100,
                          3
                        )}%
                      </span>
                    </div>
                  </div>
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
                    <%= for {color, _index} <- Enum.with_index(@commit_colors) do %>
                      <div
                        class="w-1 h-1"
                        style={"background-color: ##{color}"}
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
                      <%= for {color, index} <- Enum.with_index(@commit_colors) do %>
                        <div
                          class="h-1 w-full"
                          style={"background-color: ##{color}"}
                          title={"##{color}"}
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
              Git Commits to Colors
            </h1>
            <p class="text-center text-gray-400 mb-6 lg:mb-8 text-sm lg:text-base">
              Each color box represents the first 6 characters of a commit hash from
              <%= if @commit_colors != [] do %>
                {if @commit_count == "all",
                  do: "all",
                  else: "the most recent #{@commit_count || "100"}"} commits
              <% else %>
                your repository commits
              <% end %>.
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
                  <%= for {color, index} <- Enum.with_index(@commit_colors, 1) do %>
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
                    <.tooltip text={"##{color}"} position="tooltip-top">
                      <div
                        class="w-6 h-6 sm:w-7 sm:h-7 lg:w-8 lg:h-8 rounded border border-gray-600 flex items-center justify-center text-xs font-mono cursor-pointer hover:scale-110 active:scale-95 transition-transform"
                        style={"background-color: ##{color}"}
                        phx-click="show_color"
                        phx-value-color={color}
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
      {:ok, colors} ->
        socket =
          socket
          |> assign(:linked_directory, directory_path)
          |> assign(:commit_colors, colors)
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
    # Build git command arguments based on whether we want all commits or a specific count
    git_args =
      case count do
        "all" -> ["-C", repo_path, "log", "--format=%H"]
        _ -> ["-C", repo_path, "log", "--format=%H", "-#{count}"]
      end

    case git_cmd("git", git_args) do
      {output, 0} ->
        colors =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(&String.slice(&1, 0, 6))
          |> Enum.filter(&(String.length(&1) == 6))

        {:ok, colors}

      {error, status} ->
        error_msg =
          "Failed to get commits for repo #{repo_path} (count: #{count}): #{String.trim(error)} (status: #{status})"

        Logger.error("Git Colors: #{error_msg}")
        {:error, error_msg}
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
        # Return some mock commit hashes for testing
        mock_commits = """
        abc123def456
        789ghi012jkl
        345mno678pqr
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

  def get_most_common_color(colors) do
    colors
    |> Enum.frequencies()
    |> Enum.max_by(fn {_color, count} -> count end)
    |> elem(0)
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
end
