defmodule TelecoreWeb.PageControllerTest do
  use TelecoreWeb.ConnCase, async: true

  test "GET / redirects to /login when unauthenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/login"
  end

  describe "when authenticated" do
    setup :register_and_log_in_user

    test "GET / redirects to /routers", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/routers"
    end
  end
end
