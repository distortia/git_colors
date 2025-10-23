defmodule GitColorsWeb.CoreComponentsTest do
  use GitColorsWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import GitColorsWeb.CoreComponents

  describe "flash/1" do
    test "renders info flash" do
      assigns = %{
        kind: :info,
        flash: %{"info" => "Welcome back!"},
        id: "test-flash"
      }

      html =
        rendered_to_string(~H"""
        <.flash kind={:info} flash={@flash} id={@id} />
        """)

      assert html =~ "Welcome back!"
      assert html =~ "test-flash"
    end

    test "renders error flash" do
      assigns = %{
        kind: :error,
        flash: %{"error" => "Something went wrong!"},
        id: "error-flash"
      }

      html =
        rendered_to_string(~H"""
        <.flash kind={:error} flash={@flash} id={@id} />
        """)

      assert html =~ "Something went wrong!"
      assert html =~ "error-flash"
    end

    test "renders flash with inner block" do
      assigns = %{kind: :info, flash: %{}}

      html =
        rendered_to_string(~H"""
        <.flash kind={:info} flash={@flash}>Custom message</.flash>
        """)

      assert html =~ "Custom message"
    end
  end

  describe "button/1" do
    test "renders basic button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button>Click me</.button>
        """)

      assert html =~ "Click me"
      assert html =~ "<button"
    end

    test "renders button with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button class="btn-primary">Primary</.button>
        """)

      assert html =~ "btn-primary"
      assert html =~ "Primary"
    end
  end

  describe "input/1" do
    test "renders text input" do
      form = to_form(%{"name" => "test"})
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.input field={@form[:name]} type="text" />
        """)

      assert html =~ ~s(type="text")
      assert html =~ ~s(name="name")
    end

    test "renders select input" do
      form = to_form(%{"color" => "red"})
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.input field={@form[:color]} type="select" options={[{"Red", "red"}, {"Blue", "blue"}]} />
        """)

      assert html =~ "<select"
      assert html =~ "Red"
      assert html =~ "Blue"
    end

    test "renders checkbox input" do
      form = to_form(%{"agree" => "true"})
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.input field={@form[:agree]} type="checkbox" />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(name="agree")
    end

    test "renders textarea input" do
      form = to_form(%{"description" => "test"})
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.input field={@form[:description]} type="textarea" />
        """)

      assert html =~ "<textarea"
      assert html =~ ~s(name="description")
    end
  end

  describe "header/1" do
    test "renders header with title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.header>
          My Header
          <:subtitle>Subtitle text</:subtitle>
          <:actions>
            <button>Action</button>
          </:actions>
        </.header>
        """)

      assert html =~ "My Header"
      assert html =~ "Subtitle text"
      assert html =~ "Action"
    end
  end

  describe "table/1" do
    test "renders table with data" do
      rows = [
        %{id: 1, name: "John", email: "john@example.com"},
        %{id: 2, name: "Jane", email: "jane@example.com"}
      ]

      assigns = %{rows: rows}

      html =
        rendered_to_string(~H"""
        <.table id="users" rows={@rows}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Email">{user.email}</:col>
        </.table>
        """)

      assert html =~ "<table"
      assert html =~ "John"
      assert html =~ "Jane"
      assert html =~ "john@example.com"
      assert html =~ "jane@example.com"
      assert html =~ "Name"
      assert html =~ "Email"
    end
  end

  describe "list/1" do
    test "renders list with items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.list>
          <:item title="Name">John Doe</:item>
          <:item title="Email">john@example.com</:item>
        </.list>
        """)

      assert html =~ "Name"
      assert html =~ "John Doe"
      assert html =~ "Email"
      assert html =~ "john@example.com"
    end
  end

  describe "icon/1" do
    test "renders heroicon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.icon name="hero-home" />
        """)

      assert html =~ "hero-home"
    end
  end

  describe "tooltip/1" do
    test "renders tooltip with text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip text="Helpful tooltip">
          <button>Hover me</button>
        </.tooltip>
        """)

      assert html =~ "Helpful tooltip"
      assert html =~ "Hover me"
      assert html =~ "tooltip"
    end

    test "renders tooltip with position" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip text="Top tooltip" position="tooltip-top">
          <span>Content</span>
        </.tooltip>
        """)

      assert html =~ "Top tooltip"
      assert html =~ "tooltip-top"
      assert html =~ "Content"
    end
  end

  describe "show/2" do
    test "returns JS command for showing element" do
      js = show("#my-element")
      assert %Phoenix.LiveView.JS{} = js
    end
  end

  describe "hide/2" do
    test "returns JS command for hiding element" do
      js = hide("#my-element")
      assert %Phoenix.LiveView.JS{} = js
    end
  end

  describe "translate_error/1" do
    test "translates simple error message" do
      error = {"can't be blank", []}
      result = translate_error(error)
      assert is_binary(result)
      assert result != ""
    end

    test "translates error with interpolation" do
      error = {"should be at least %{count} character(s)", [count: 3]}
      result = translate_error(error)
      assert result =~ "3"
    end
  end

  describe "translate_errors/2" do
    test "translates list of errors" do
      errors = [
        {:name, {"can't be blank", []}},
        {:name, {"should be at least %{count} character(s)", [count: 3]}}
      ]

      results = translate_errors(errors, :name)
      assert is_list(results)
      assert length(results) == 2

      Enum.each(results, fn result ->
        assert is_binary(result)
        assert result != ""
      end)
    end

    test "handles empty error list" do
      results = translate_errors([], :name)
      assert results == []
    end

    test "filters errors by field" do
      errors = [
        {:name, {"can't be blank", []}},
        {:email, {"is invalid", []}},
        {:name, {"is too short", []}}
      ]

      results = translate_errors(errors, :name)
      assert length(results) == 2
    end
  end
end
