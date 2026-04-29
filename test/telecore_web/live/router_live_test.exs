defmodule TelecoreWeb.RouterLiveTest do
  use TelecoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Index" do
    test "lists routers", %{conn: conn} do
      router = insert(:mikrotik_router, label: "POP-A")
      {:ok, _view, html} = live(conn, ~p"/routers")
      assert html =~ "POP-A"
      assert html =~ router.url
    end

    test "creates a router", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/routers/new")

      view
      |> form("#router-form",
        router: %{
          label: "POP-NEW",
          url: "https://10.99.0.1",
          username: "admin",
          password: "secret"
        }
      )
      |> render_submit()

      assert_patch(view, ~p"/routers")
    end
  end

  # Show test omitted — requires more elaborate setup with the adapter mock.
  # The LiveView itself is exercised via manual testing.
end
