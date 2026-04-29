defmodule Telecore.Mikrotik.Fake do
  @moduledoc """
  In-memory implementation of `Telecore.Mikrotik.Client` for development.
  Seeds realistic data per router on first access.
  """

  use GenServer
  @behaviour Telecore.Mikrotik.Client

  alias Telecore.Mikrotik.{Router, Error}

  # --- Public client API (behaviour callbacks) ---

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def list_secrets(%Router{id: id}), do: call({:list, id, :secrets})

  @impl true
  def get_secret(%Router{id: id}, name), do: call({:get, id, :secrets, "name", name})

  @impl true
  def create_secret(%Router{id: id}, attrs), do: call({:create, id, :secrets, attrs})

  @impl true
  def update_secret(%Router{id: id}, name, attrs), do: call({:update, id, :secrets, "name", name, attrs})

  @impl true
  def delete_secret(%Router{id: id}, name), do: call({:delete, id, :secrets, "name", name})

  @impl true
  def enable_secret(%Router{id: id}, name), do: call({:set_disabled, id, name, "false"})

  @impl true
  def disable_secret(%Router{id: id}, name), do: call({:set_disabled, id, name, "true"})

  @impl true
  def list_sessions(%Router{id: id}), do: call({:list, id, :sessions})

  @impl true
  def disconnect_session(%Router{id: id}, session_id),
    do: call({:delete, id, :sessions, ".id", session_id})

  @impl true
  def list_queues(%Router{id: id}), do: call({:list, id, :queues})

  @impl true
  def create_queue(%Router{id: id}, attrs), do: call({:create, id, :queues, attrs})

  @impl true
  def update_queue(%Router{id: id}, name, attrs), do: call({:update, id, :queues, "name", name, attrs})

  @impl true
  def delete_queue(%Router{id: id}, name), do: call({:delete, id, :queues, "name", name})

  defp call(msg), do: GenServer.call(__MODULE__, msg)

  # --- GenServer callbacks ---

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:list, router_id, kind}, _from, state) do
    state = ensure_router(state, router_id)
    {:reply, {:ok, get_in(state, [router_id, kind])}, state}
  end

  def handle_call({:get, router_id, kind, key, value}, _from, state) do
    state = ensure_router(state, router_id)
    items = get_in(state, [router_id, kind])

    case Enum.find(items, &(&1[key] == value)) do
      nil -> {:reply, {:error, not_found(value)}, state}
      item -> {:reply, {:ok, item}, state}
    end
  end

  def handle_call({:create, router_id, kind, attrs}, _from, state) do
    state = ensure_router(state, router_id)
    items = get_in(state, [router_id, kind])
    new = Map.put(attrs, ".id", "*#{System.unique_integer([:positive])}")
    state = put_in(state, [router_id, kind], items ++ [new])
    {:reply, {:ok, new}, state}
  end

  def handle_call({:update, router_id, kind, key, value, attrs}, _from, state) do
    state = ensure_router(state, router_id)
    items = get_in(state, [router_id, kind])

    case Enum.find_index(items, &(&1[key] == value)) do
      nil ->
        {:reply, {:error, not_found(value)}, state}

      idx ->
        updated = Map.merge(Enum.at(items, idx), attrs)
        items = List.replace_at(items, idx, updated)
        state = put_in(state, [router_id, kind], items)
        {:reply, {:ok, updated}, state}
    end
  end

  def handle_call({:delete, router_id, kind, key, value}, _from, state) do
    state = ensure_router(state, router_id)
    items = get_in(state, [router_id, kind])

    case Enum.find_index(items, &(&1[key] == value)) do
      nil ->
        {:reply, {:error, not_found(value)}, state}

      idx ->
        items = List.delete_at(items, idx)
        state = put_in(state, [router_id, kind], items)
        {:reply, {:ok, :ok}, state}
    end
  end

  def handle_call({:set_disabled, router_id, name, flag}, _from, state) do
    state = ensure_router(state, router_id)
    secrets = get_in(state, [router_id, :secrets])

    case Enum.find_index(secrets, &(&1["name"] == name)) do
      nil ->
        {:reply, {:error, not_found(name)}, state}

      idx ->
        secrets = List.update_at(secrets, idx, &Map.put(&1, "disabled", flag))
        state = put_in(state, [router_id, :secrets], secrets)

        # Disabling: remove sessão. Enabling: nada.
        state =
          if flag == "true" do
            sessions = get_in(state, [router_id, :sessions])
            sessions = Enum.reject(sessions, &(&1["name"] == name))
            put_in(state, [router_id, :sessions], sessions)
          else
            state
          end

        {:reply, {:ok, :ok}, state}
    end
  end

  # --- Helpers ---

  defp ensure_router(state, router_id) do
    if Map.has_key?(state, router_id) do
      state
    else
      Map.put(state, router_id, seed())
    end
  end

  defp seed do
    %{
      secrets: [
        %{".id" => "*1", "name" => "joao", "password" => "pwjoao", "profile" => "10mbps", "service" => "pppoe", "disabled" => "false", "comment" => "Cliente residencial"},
        %{".id" => "*2", "name" => "maria", "password" => "pwmaria", "profile" => "50mbps", "service" => "pppoe", "disabled" => "false", "comment" => ""},
        %{".id" => "*3", "name" => "pedro", "password" => "pwpedro", "profile" => "100mbps", "service" => "pppoe", "disabled" => "false", "comment" => "Empresa"}
      ],
      sessions: [
        %{".id" => "*A1", "name" => "joao", "address" => "10.0.0.5", "uptime" => "2h13m", "service" => "pppoe", "caller-id" => "aa:bb:cc:dd:ee:01"},
        %{".id" => "*A2", "name" => "maria", "address" => "10.0.0.6", "uptime" => "47m", "service" => "pppoe", "caller-id" => "aa:bb:cc:dd:ee:02"}
      ],
      queues: [
        %{".id" => "*Q1", "name" => "joao", "target" => "10.0.0.5/32", "max-limit" => "10M/10M"},
        %{".id" => "*Q2", "name" => "maria", "target" => "10.0.0.6/32", "max-limit" => "50M/50M"},
        %{".id" => "*Q3", "name" => "pedro", "target" => "10.0.0.7/32", "max-limit" => "100M/100M"}
      ]
    }
  end

  defp not_found(value), do: %Error{code: :not_found, message: "#{value} not found"}
end
