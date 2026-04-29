defmodule TelecoreWeb.Auth do
  @moduledoc """
  Cookie-session helpers and plugs for the login system.

  - `log_in_user/2` and `log_out_user/1` manage the session.
  - `fetch_current_user/2` is a plug that loads the user from the session into `assigns.current_user`.
  - `require_authenticated_user/2` is a plug that halts with a redirect when no user is logged in.
  """
  use TelecoreWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Telecore.Accounts

  @session_key :user_id

  @doc """
  Logs the user in by writing their id to the session and redirecting to `/`.

  Renews the session id to mitigate fixation attacks.
  """
  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(@session_key, user.id)
    |> redirect(to: ~p"/")
  end

  @doc """
  Clears the session and redirects to `/login`.
  """
  def log_out_user(conn) do
    conn
    |> renew_session()
    |> redirect(to: ~p"/login")
  end

  @doc """
  Plug. Loads the current user (if any) into `assigns.current_user`.
  Silently clears the session when the stored id doesn't resolve to a user.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, @session_key)
    user = user_id && safe_get_user(user_id)

    cond do
      user ->
        assign(conn, :current_user, user)

      user_id ->
        conn |> renew_session() |> assign(:current_user, nil)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  @doc """
  Plug. Halts with a redirect to `/login` when no user is present.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  defp safe_get_user(id) do
    Accounts.get_user!(id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
