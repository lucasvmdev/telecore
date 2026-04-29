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
  def list_secrets(%Router{} = r), do: call({:list, r, :secrets})

  @impl true
  def get_secret(%Router{} = r, name), do: call({:get, r, :secrets, "name", name})

  @impl true
  def create_secret(%Router{} = r, attrs), do: call({:create, r, :secrets, attrs})

  @impl true
  def update_secret(%Router{} = r, name, attrs),
    do: call({:update, r, :secrets, "name", name, attrs})

  @impl true
  def delete_secret(%Router{} = r, name), do: call({:delete, r, :secrets, "name", name})

  @impl true
  def enable_secret(%Router{} = r, name), do: call({:set_disabled, r, name, "false"})

  @impl true
  def disable_secret(%Router{} = r, name), do: call({:set_disabled, r, name, "true"})

  @impl true
  def list_sessions(%Router{} = r), do: call({:list, r, :sessions})

  @impl true
  def disconnect_session(%Router{} = r, session_id),
    do: call({:delete, r, :sessions, ".id", session_id})

  @impl true
  def list_queues(%Router{} = r), do: call({:list, r, :queues})

  @impl true
  def create_queue(%Router{} = r, attrs), do: call({:create, r, :queues, attrs})

  @impl true
  def update_queue(%Router{} = r, name, attrs),
    do: call({:update, r, :queues, "name", name, attrs})

  @impl true
  def delete_queue(%Router{} = r, name), do: call({:delete, r, :queues, "name", name})

  defp call(msg), do: GenServer.call(__MODULE__, msg)

  # --- GenServer callbacks ---

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:list, router, kind}, _from, state) do
    state = ensure_router(state, router)
    {:reply, {:ok, get_in(state, [router.id, kind])}, state}
  end

  def handle_call({:get, router, kind, key, value}, _from, state) do
    state = ensure_router(state, router)
    items = get_in(state, [router.id, kind])

    case Enum.find(items, &(&1[key] == value)) do
      nil -> {:reply, {:error, not_found(value)}, state}
      item -> {:reply, {:ok, item}, state}
    end
  end

  def handle_call({:create, router, kind, attrs}, _from, state) do
    state = ensure_router(state, router)
    items = get_in(state, [router.id, kind])
    new = Map.put(attrs, ".id", "*#{System.unique_integer([:positive])}")
    state = put_in(state, [router.id, kind], items ++ [new])
    {:reply, {:ok, new}, state}
  end

  def handle_call({:update, router, kind, key, value, attrs}, _from, state) do
    state = ensure_router(state, router)
    items = get_in(state, [router.id, kind])

    case Enum.find_index(items, &(&1[key] == value)) do
      nil ->
        {:reply, {:error, not_found(value)}, state}

      idx ->
        updated = Map.merge(Enum.at(items, idx), attrs)
        items = List.replace_at(items, idx, updated)
        state = put_in(state, [router.id, kind], items)
        {:reply, {:ok, updated}, state}
    end
  end

  def handle_call({:delete, router, kind, key, value}, _from, state) do
    state = ensure_router(state, router)
    items = get_in(state, [router.id, kind])

    case Enum.find_index(items, &(&1[key] == value)) do
      nil ->
        {:reply, {:error, not_found(value)}, state}

      idx ->
        items = List.delete_at(items, idx)
        state = put_in(state, [router.id, kind], items)
        {:reply, {:ok, :ok}, state}
    end
  end

  def handle_call({:set_disabled, router, name, flag}, _from, state) do
    state = ensure_router(state, router)
    secrets = get_in(state, [router.id, :secrets])

    case Enum.find_index(secrets, &(&1["name"] == name)) do
      nil ->
        {:reply, {:error, not_found(name)}, state}

      idx ->
        secrets = List.update_at(secrets, idx, &Map.put(&1, "disabled", flag))
        state = put_in(state, [router.id, :secrets], secrets)

        # Disabling: remove sessão. Enabling: nada.
        state =
          if flag == "true" do
            sessions = get_in(state, [router.id, :sessions])
            sessions = Enum.reject(sessions, &(&1["name"] == name))
            put_in(state, [router.id, :sessions], sessions)
          else
            state
          end

        {:reply, {:ok, :ok}, state}
    end
  end

  # --- Helpers ---

  defp ensure_router(state, %Router{id: id} = router) do
    if Map.has_key?(state, id) do
      state
    else
      Map.put(state, id, seed(router))
    end
  end

  # Pool of names used to generate per-router clients. Each router picks a
  # window from this list deterministically (rotating by router-id hash) so
  # that no two routers share the same set of clients.
  @name_pool ~w(joao maria pedro ana carlos fernanda rafael patricia lucas
                juliana bruno camila ricardo amanda diego sofia thiago
                isabela leonardo gabriela)

  @profiles [
    {"10mbps", "10M/10M"},
    {"25mbps", "25M/25M"},
    {"50mbps", "50M/50M"},
    {"100mbps", "100M/100M"},
    {"200mbps", "200M/200M"}
  ]

  @uptimes ["2h13m", "47m", "5d 2h", "1d 14h", "3h 22m", "12h", "8d 4h", "21m"]

  # Deterministic per-router seed. Generates 3–5 clients with distinct names
  # and IPs derived from the router's URL subnet. Some clients are disabled
  # based on a hash of the router id, so the UI shows different states.
  defp seed(%Router{id: id, url: url}) do
    count = 3 + rem(:erlang.phash2(id, 3), 3)
    offset = rem(:erlang.phash2(id, length(@name_pool)), length(@name_pool))

    names =
      0..(count - 1)
      |> Enum.map(fn i -> Enum.at(@name_pool, rem(offset + i, length(@name_pool))) end)

    disabled_idxs =
      case :erlang.phash2({id, :disabled}, 4) do
        0 -> []
        1 -> [0]
        2 -> [0, 1]
        3 -> [count - 1]
      end

    subnet = subnet_from_url(url)

    secrets =
      names
      |> Enum.with_index()
      |> Enum.map(fn {name, i} ->
        {profile, _} =
          Enum.at(
            @profiles,
            rem(:erlang.phash2({id, name}, length(@profiles)), length(@profiles))
          )

        %{
          ".id" => "*S#{i + 1}",
          "name" => name,
          "password" => "pw_#{name}",
          "profile" => profile,
          "service" => "pppoe",
          "comment" => comment_for(i),
          "disabled" => if(i in disabled_idxs, do: "true", else: "false")
        }
      end)

    sessions =
      secrets
      |> Enum.with_index()
      |> Enum.reject(fn {s, _} -> s["disabled"] == "true" end)
      |> Enum.map(fn {s, i} ->
        %{
          ".id" => "*A#{i + 1}",
          "name" => s["name"],
          "address" => "#{subnet}.#{10 + i}",
          "uptime" =>
            Enum.at(
              @uptimes,
              rem(:erlang.phash2({id, s["name"]}, length(@uptimes)), length(@uptimes))
            ),
          "service" => "pppoe",
          "caller-id" => mac_for(id, i)
        }
      end)

    queues =
      secrets
      |> Enum.with_index()
      |> Enum.map(fn {s, i} ->
        {profile, max_limit} =
          Enum.find(@profiles, {"10mbps", "10M/10M"}, fn {p, _} -> p == s["profile"] end)

        _ = profile

        %{
          ".id" => "*Q#{i + 1}",
          "name" => s["name"],
          "target" => "#{subnet}.#{10 + i}/32",
          "max-limit" => max_limit
        }
      end)

    %{secrets: secrets, sessions: sessions, queues: queues}
  end

  # Extract the first three octets of an IPv4 from the URL host.
  # Falls back to "10.0.0" when the URL has no IP host.
  defp subnet_from_url(url) when is_binary(url) do
    case Regex.run(~r/(\d+)\.(\d+)\.(\d+)\.\d+/, url) do
      [_, a, b, c] -> "#{a}.#{b}.#{c}"
      _ -> "10.0.0"
    end
  end

  defp subnet_from_url(_), do: "10.0.0"

  defp comment_for(0), do: "Cliente residencial"
  defp comment_for(1), do: ""
  defp comment_for(2), do: "Empresa"
  defp comment_for(3), do: "Plano premium"
  defp comment_for(_), do: "Cliente"

  defp mac_for(id, i) do
    bytes = :erlang.phash2({id, i}, 0xFFFFFF)

    b1 = bytes |> div(0x10000) |> Integer.to_string(16) |> String.pad_leading(2, "0")
    b2 = bytes |> div(0x100) |> rem(0x100) |> Integer.to_string(16) |> String.pad_leading(2, "0")
    b3 = bytes |> rem(0x100) |> Integer.to_string(16) |> String.pad_leading(2, "0")

    "aa:bb:cc:#{b1}:#{b2}:#{b3}"
  end

  defp not_found(value), do: %Error{code: :not_found, message: "#{value} not found"}
end
