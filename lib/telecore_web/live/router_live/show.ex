defmodule TelecoreWeb.RouterLive.Show do
  use TelecoreWeb, :live_view

  alias Telecore.Mikrotik

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    router = Mikrotik.get_router!(id)
    counts = load_counts(router)
    {:ok, assign(socket, router: router, counts: counts)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, socket.assigns.router.label)}
  end

  @impl true
  def handle_info({TelecoreWeb.RouterLive.FormComponent, {:saved, router}}, socket) do
    {:noreply, assign(socket, :router, Mikrotik.get_router!(router.id))}
  end

  defp load_counts(router) do
    %{
      sessions: count_or_dash(Mikrotik.list_sessions(router)),
      secrets: count_or_dash(Mikrotik.list_secrets(router)),
      queues: count_or_dash(Mikrotik.list_queues(router))
    }
  end

  defp count_or_dash({:ok, list}), do: length(list)
  defp count_or_dash(_), do: "—"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.router_nav router={@router} active={:show} />

      <.header>
        {@router.label}
        <:subtitle>{@router.url}</:subtitle>
        <:actions>
          <.link patch={~p"/routers/#{@router.id}/edit"} class="btn btn-ghost btn-sm">Editar</.link>
        </:actions>
      </.header>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <.link navigate={~p"/routers/#{@router.id}/sessions"} class="card bg-base-200 p-4 hover:bg-base-300">
          <div class="text-3xl font-bold">{@counts.sessions}</div>
          <div class="text-sm opacity-60">Sessões ativas</div>
        </.link>

        <.link navigate={~p"/routers/#{@router.id}/secrets"} class="card bg-base-200 p-4 hover:bg-base-300">
          <div class="text-3xl font-bold">{@counts.secrets}</div>
          <div class="text-sm opacity-60">Clientes</div>
        </.link>

        <div class="card bg-base-200 p-4">
          <div class="text-3xl font-bold">{@counts.queues}</div>
          <div class="text-sm opacity-60">Queues</div>
        </div>
      </div>

      <.modal :if={@live_action == :edit} id="router-modal" show on_cancel={JS.patch(~p"/routers/#{@router.id}")}>
        <.live_component
          module={TelecoreWeb.RouterLive.FormComponent}
          id={@router.id}
          title="Editar Roteador"
          action={:edit}
          router={@router}
          patch={~p"/routers/#{@router.id}"}
        />
      </.modal>
    </Layouts.app>
    """
  end
end
