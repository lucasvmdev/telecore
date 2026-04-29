defmodule TelecoreWeb.PageControllerTest do
  use TelecoreWeb.ConnCase, async: true

  test "GET / redirects to /login when unauthenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/login"
  end

  describe "when authenticated" do
    setup :register_and_log_in_user

    test "GET / renders the welcome page with the user's email", %{conn: conn, user: user} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "Welcome"
      assert response =~ user.email
      assert response =~ "Sign out"
    end
  end
end
