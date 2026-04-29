defmodule TelecoreWeb.SessionControllerTest do
  use TelecoreWeb.ConnCase, async: true

  describe "GET /login" do
    test "renders the form", %{conn: conn} do
      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "Sign in"
      assert response =~ "Email"
      assert response =~ "Password"
    end
  end

  describe "POST /login" do
    test "logs the user in with valid credentials", %{conn: conn} do
      user = insert(:user)
      conn = post(conn, ~p"/login", %{"email" => user.email, "password" => valid_password()})

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_id) == user.id
    end

    test "redirects despite mixed-case email", %{conn: conn} do
      insert(:user, email: "case@telecore.test")

      conn =
        post(conn, ~p"/login", %{"email" => "CASE@telecore.test", "password" => valid_password()})

      assert redirected_to(conn) == ~p"/"
    end

    test "re-renders the form with an error on bad password", %{conn: conn} do
      user = insert(:user)
      conn = post(conn, ~p"/login", %{"email" => user.email, "password" => "wrong-password"})

      assert html_response(conn, 200) =~ "Invalid email or password"
      refute get_session(conn, :user_id)
    end

    test "re-renders the form with an error on unknown email", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{"email" => "ghost@telecore.test", "password" => "anything12"})

      assert html_response(conn, 200) =~ "Invalid email or password"
      refute get_session(conn, :user_id)
    end
  end

  describe "DELETE /logout" do
    setup :register_and_log_in_user

    test "clears the session and redirects to /login", %{conn: conn} do
      conn = delete(conn, ~p"/logout")

      assert redirected_to(conn) == ~p"/login"
      refute get_session(conn, :user_id)
    end
  end
end
