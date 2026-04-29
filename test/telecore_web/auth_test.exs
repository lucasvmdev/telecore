defmodule TelecoreWeb.AuthTest do
  use TelecoreWeb.ConnCase, async: true

  import Telecore.Factory

  alias TelecoreWeb.Auth

  describe "on_mount/4 :ensure_authenticated" do
    test "continues with current_user when session has valid user_id" do
      user = insert(:user)
      session = %{"user_id" => user.id}
      socket = %Phoenix.LiveView.Socket{}

      assert {:cont, socket} = Auth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
    end

    test "halts and redirects when session has no user_id" do
      socket = %Phoenix.LiveView.Socket{}
      assert {:halt, socket} = Auth.on_mount(:ensure_authenticated, %{}, %{}, socket)
      assert socket.redirected == {:redirect, %{to: "/login", status: 302}}
    end

    test "halts and redirects when user_id is invalid" do
      session = %{"user_id" => Ecto.UUID.generate()}
      socket = %Phoenix.LiveView.Socket{}
      assert {:halt, _} = Auth.on_mount(:ensure_authenticated, %{}, session, socket)
    end
  end
end
