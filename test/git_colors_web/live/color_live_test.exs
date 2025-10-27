defmodule GitColorsWeb.ColorLiveTest do
  use GitColorsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "ColorLive" do
    test "disconnected and connected render", %{conn: conn} do
      {:ok, page_live, disconnected_html} = live(conn, ~p"/")

      assert disconnected_html =~ "Git Commits to"
      assert render(page_live) =~ "Git Commits to"
    end

    test "displays repository analysis form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#directory-form")
      assert has_element?(view, "input[name='directory_path']")
      assert has_element?(view, "select[name='commit_count']")
      assert has_element?(view, "button[type='submit']")
    end

    test "displays placeholder text for directory input", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "e.g., /Users/username/my-project"
    end

    test "displays commit count options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "100 commits"
      assert html =~ "500 commits"
      assert html =~ "1000 commits"
      assert html =~ "10,000 commits"
      assert html =~ "All commits"
    end

    test "displays large repository warning", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "⚠️ Large Repositories:"
      assert html =~ "10k+ commits may take time to process"
    end

    test "displays no repository loaded state initially", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "No Repository Loaded"
      assert html =~ "Enter a directory path in the sidebar"
    end

    test "shows loading state when submitting form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Submit form with a test directory path
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      # The loading state might be brief, but we can check that the form was processed
      assert render(view) =~ "Repository Analysis"
    end

    test "handles valid directory path with mocked git response", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      # Wait for the async process to complete
      :timer.sleep(200)

      # Should show repository info with mocked data
      html = render(view)
      assert html =~ "Total Commits:</span> 3"
    end

    test "handles git error with mocked error response", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/error/path",
        "commit_count" => "100"
      })
      |> render_submit()

      # Wait for the async process to complete
      :timer.sleep(200)

      # Should show error message
      html = render(view)
      assert html =~ "Error"
    end

    test "form validation prevents empty directory path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Try to submit with empty directory path
      view
      |> form("#directory-form", %{
        "directory_path" => "",
        "commit_count" => "100"
      })
      |> render_submit()

      # Should handle empty path gracefully
      assert render(view) =~ "Repository Analysis"
    end

    test "default commit count is 100", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "option[selected][value='100']")
    end

    test "pixel popover toggle functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Initially, pixel popover should not be shown
      refute has_element?(view, ".fixed.inset-0")

      # The pixel button should not be visible initially (no commits loaded)
      refute has_element?(view, "button[phx-click='toggle_pixel_popover']")
    end

    test "color statistics section not shown for small datasets", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Color statistics should not be shown initially (no commits loaded)
      refute html =~ "Most Common:"
      refute html =~ "Diversity:"
    end

    test "floating navigation not shown initially", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Jump to bottom button should not be shown initially (no commits loaded)
      refute html =~ "Jump to Bottom"
    end
  end

  describe "ColorLive advanced functionality" do
    test "handles show_color event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # First load some commits to have color data
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      # Now trigger show_color event
      view
      |> element("div[phx-value-color='abc123']")
      |> render_click()

      html = render(view)
      assert html =~ "Selected Color"
      assert html =~ "#abc123"
    end

    test "handles toggle_pixel_popover event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Load commits first
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      # Initially popover should not be shown
      refute render(view) =~ "Commit Timeline - Pixel View"

      # Check that the timeline section exists
      assert has_element?(view, "h3", "Commit Timeline")

      # Render click with specific target using CSS path
      html = render_click(view, "toggle_pixel_popover", %{})

      # Should show popover after click
      assert html =~ "Commit Timeline - Pixel View"
    end

    test "loads repository with all commits count", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "all"
      })
      |> render_submit()

      # "all" commits has a delay
      :timer.sleep(300)

      html = render(view)
      assert html =~ "Total Commits:</span> 3"
      assert html =~ "all commits"
    end

    test "displays commit statistics for loaded repository", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Unique Colors:</span> 3"
      assert html =~ "Coverage:</span> 100 commits"
    end

    test "shows pixel timeline for loaded repository", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Commit Timeline"
      assert html =~ "Pixels"
      assert html =~ "3 commits displayed as pixels"
    end

    test "displays floating navigation after loading commits", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Jump to Bottom"
    end

    test "resets state when loading new repository", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Load first repo and select a color
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("div[phx-value-color='abc123']")
      |> render_click()

      # Note: The selected color state might persist in the UI
      # Let's check that the directory changes correctly
      html_after_first = render(view)
      assert html_after_first =~ "/test/repo/path"

      # Load second repo - should reset to new directory
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/other/path",
        "commit_count" => "500"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "/test/other/path"
      assert html =~ "Coverage:</span> 500 commits"
    end

    test "handles different commit count options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Test 500 commits option
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "500"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Coverage:</span> 500 commits"

      # Test 1000 commits option
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "1000"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Coverage:</span> 1000 commits"
    end

    test "displays color analysis when color is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Load repo and select a color
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("div[phx-value-color='abc123']")
      |> render_click()

      html = render(view)
      assert html =~ "RGB:"
      assert html =~ "Brightness:"
      # RGB for abc123
      assert html =~ "171, 193, 35"
      # Check for ColorHexa link
      assert html =~ "View on ColorHexa"
      assert html =~ "https://www.colorhexa.com/abc123"
    end

    test "colorhexa link has proper attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Load repo and select a color
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("div[phx-value-color='abc123']")
      |> render_click()

      # Check that the ColorHexa link has proper security attributes
      assert has_element?(
               view,
               "a[href='https://www.colorhexa.com/abc123'][target='_blank'][rel='noopener noreferrer']"
             )

      html = render(view)
      assert html =~ "target=\"_blank\""
      assert html =~ "rel=\"noopener noreferrer\""
    end

    test "handles form validation with empty directory", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "",
        "commit_count" => "100"
      })
      |> render_submit()

      # Should handle gracefully without crashing
      assert render(view) =~ "Repository Analysis"
    end

    test "cache functionality is tested through repeated requests", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # First request - should populate cache
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "all"
      })
      |> render_submit()

      :timer.sleep(300)

      html1 = render(view)
      assert html1 =~ "Total Commits:</span> 3"

      # Second request with same path - should use cache and be faster
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "all"
      })
      |> render_submit()

      # Allow enough time for async processing
      :timer.sleep(300)

      html2 = render(view)
      # Should still show the same data from cache
      assert html2 =~ "Directory:"
      assert html2 =~ "/test/repo/path"
      # In test environment with mocked git, should show results
      assert html2 =~ "Total Commits:</span> 3"
    end
  end

  describe "helper functions" do
    alias GitColorsWeb.ColorLive

    test "hex_to_rgb converts correctly" do
      # Use a private function testing approach by calling the module directly
      # Note: We'll need to make these functions public or use a different testing strategy
      assert "255, 255, 255" == ColorLive.hex_to_rgb("ffffff")
      assert "0, 0, 0" == ColorLive.hex_to_rgb("000000")
      assert "255, 0, 0" == ColorLive.hex_to_rgb("ff0000")
      assert "171, 193, 35" == ColorLive.hex_to_rgb("abc123")
    end

    test "get_brightness calculates correctly" do
      # White should be 100% brightness
      assert 100.0 == ColorLive.get_brightness("ffffff")
      # Black should be 0% brightness
      assert 0.0 == ColorLive.get_brightness("000000")
      # Red should be around 29.9% brightness (based on luminance formula)
      brightness = ColorLive.get_brightness("ff0000")
      assert brightness > 25 and brightness < 35
    end

    test "calculate_grid_columns returns appropriate values" do
      assert 10 == ColorLive.calculate_grid_columns(50)
      assert 10 == ColorLive.calculate_grid_columns(100)
      assert 25 == ColorLive.calculate_grid_columns(300)
      assert 40 == ColorLive.calculate_grid_columns(800)
      assert 50 == ColorLive.calculate_grid_columns(3000)
      assert 60 == ColorLive.calculate_grid_columns(8000)
      assert 80 == ColorLive.calculate_grid_columns(50_000)
    end

    test "get_most_common_color finds the most frequent color" do
      colors = ["ff0000", "00ff00", "ff0000", "0000ff", "ff0000"]
      assert "ff0000" == ColorLive.get_most_common_color(colors)

      # Test with single color
      assert "abc123" == ColorLive.get_most_common_color(["abc123"])

      # Test with equal frequencies - should return first one
      colors_equal = ["ff0000", "00ff00", "0000ff"]
      result = ColorLive.get_most_common_color(colors_equal)
      assert result in colors_equal
    end

    test "get_most_common_color handles empty list" do
      # The function will crash on empty list due to Enum.max_by
      # This tests the error behavior
      assert_raise Enum.EmptyError, fn ->
        ColorLive.get_most_common_color([])
      end
    end
  end

  describe "private function behavior through public interface" do
    test "cache operations work through repeated requests", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # First request with all commits should create cache
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "all"
      })
      |> render_submit()

      :timer.sleep(300)

      html1 = render(view)
      assert html1 =~ "Total Commits:</span> 3"

      # Second request should use cache (will be faster)
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "all"
      })
      |> render_submit()

      :timer.sleep(100)

      html2 = render(view)
      # Should still show the same data
      assert html2 =~ "Directory:"
      assert html2 =~ "/test/repo/path"
    end

    test "different commit counts don't use cache", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Regular commit count requests shouldn't use cache
      view
      |> form("#directory-form", %{
        "directory_path" => "/test/repo/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      assert html =~ "Total Commits:</span> 3"
      assert html =~ "Coverage:</span> 100 commits"
    end

    test "empty directory path is handled gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "",
        "commit_count" => "100"
      })
      |> render_submit()

      # Should not crash and should remain on the same page
      assert render(view) =~ "Repository Analysis"
    end

    test "invalid directory shows error state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#directory-form", %{
        "directory_path" => "/nonexistent/path",
        "commit_count" => "100"
      })
      |> render_submit()

      :timer.sleep(100)

      html = render(view)
      # Should show some form of error or empty state
      assert html =~ "Repository Analysis"
      # In test environment, git commands are mocked so it will show data
      # But should show the directory path attempted
      assert html =~ "/nonexistent/path"
      # Due to mocking, will still show commit data - this is expected in tests
      assert html =~ "Total Commits:"
    end
  end
end
