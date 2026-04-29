defmodule Telecore.Mikrotik do
  alias Telecore.{Repo, Mikrotik.Router}

  # --- Router CRUD ---

  def list_routers, do: Repo.all(Router)

  def get_router!(id), do: Repo.get!(Router, id)

  def create_router(attrs \\ %{}) do
    %Router{}
    |> Router.changeset(attrs)
    |> Repo.insert()
  end

  def update_router(%Router{} = router, attrs) do
    router
    |> Router.changeset(attrs)
    |> Repo.update()
  end

  def delete_router(%Router{} = router), do: Repo.delete(router)

  # --- Adapter delegation ---

  defp adapter, do: Application.fetch_env!(:telecore, :mikrotik_adapter)

  def list_secrets(router), do: adapter().list_secrets(router)
  def get_secret(router, name), do: adapter().get_secret(router, name)
  def create_secret(router, attrs), do: adapter().create_secret(router, attrs)
  def update_secret(router, name, attrs), do: adapter().update_secret(router, name, attrs)
  def delete_secret(router, name), do: adapter().delete_secret(router, name)
  def enable_secret(router, name), do: adapter().enable_secret(router, name)
  def disable_secret(router, name), do: adapter().disable_secret(router, name)

  def list_sessions(router), do: adapter().list_sessions(router)
  def disconnect_session(router, session_id), do: adapter().disconnect_session(router, session_id)

  def list_queues(router), do: adapter().list_queues(router)
  def create_queue(router, attrs), do: adapter().create_queue(router, attrs)
  def update_queue(router, name, attrs), do: adapter().update_queue(router, name, attrs)
  def delete_queue(router, name), do: adapter().delete_queue(router, name)
end
