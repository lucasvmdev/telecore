defmodule TelecoreWeb.SessionController do
  use TelecoreWeb, :controller

  alias Telecore.Accounts
  alias TelecoreWeb.Auth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> render(:new, error_message: "Invalid email or password.")

      user ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Auth.log_in_user(user)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out.")
    |> Auth.log_out_user()
  end
end
