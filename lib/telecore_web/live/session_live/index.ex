defmodule TelecoreWeb.SessionLive.Index do
  use TelecoreWeb, :live_view

  alias Telecore.Mikrotik

  @tick_interval 5_000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    router = Mikrotik.get_router!(id)
    if connected?(socket), do: schedule_tick()

    {:ok,
     socket
     |> assign(:router, router)
     |> assign(:page_title, "Sessões — #{router.label}")
     |> load_sessions()}
  end

  @impl true
  def handle_info(:tick, socket) do
    schedule_tick()
    {:noreply, load_sessions(socket)}
  end

  @impl true
  def handle_event("disconnect", %{"id" => id}, socket) do
    case Mikrotik.disconnect_session(socket.assigns.router, id) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Sessão desconectada.") |> load_sessions()}

      {:error, %{message: m}} ->
        {:noreply, put_flash(socket, :error, "Falha: #{m}")}
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @tick_interval)

  defp load_sessions(socket) do
    case Mikrotik.list_sessions(socket.assigns.router) do
      {:ok, sessions} ->
        assign(socket, sessions: sessions, last_error: nil, updated_at: DateTime.utc_now())

      {:error, %{} = e} ->
        assign(socket, sessions: [], last_error: e, updated_at: DateTime.utc_now())
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.router_nav router={@router} active={:sessions} />

      <.header>
        Sessões ativas
        <:subtitle>Atualizando a cada 5 segundos</:subtitle>
      </.header>

      <div :if={@last_error} class="alert alert-error">
        <span>Erro: {@last_error.message}</span>
      </div>

      <table class="table">
        <thead>
          <tr>
            <th>Nome</th>
            <th>IP</th>
            <th>Service</th>
            <th>Uptime</th>
            <th>Caller-ID</th>
            <th class="text-right">Ações</th>
          </tr>
        </thead>
        <tbody id="sessions">
          <tr :for={s <- @sessions} id={"session-#{s[".id"]}"}>
            <td>{s["name"]}</td>
            <td><code>{s["address"]}</code></td>
            <td>{s["service"]}</td>
            <td>{s["uptime"]}</td>
            <td><code class="text-xs">{s["caller-id"]}</code></td>
            <td class="text-right">
              <.link
                phx-click={JS.push("disconnect", value: %{id: s[".id"]})}
                data-confirm={"Desconectar #{s["name"]}?"}
                class="link link-error"
              >
                Desconectar
              </.link>
            </td>
          </tr>
        </tbody>
      </table>

      <p :if={@sessions == [] and is_nil(@last_error)} class="text-center opacity-60 py-12">
        Nenhuma sessão ativa neste roteador.
      </p>
    </Layouts.app>
    """
  end
end
