defmodule TelecoreWeb.RouterLive.Index do
  use TelecoreWeb, :live_view

  alias Telecore.Mikrotik
  alias Telecore.Mikrotik.Router

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :routers, Mikrotik.list_routers())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Roteadores")
    |> assign(:router, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Novo Roteador")
    |> assign(:router, %Router{})
  end

  @impl true
  def handle_info({TelecoreWeb.RouterLive.FormComponent, {:saved, _router}}, socket) do
    {:noreply, assign(socket, :routers, Mikrotik.list_routers())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    router = Mikrotik.get_router!(id)
    {:ok, _} = Mikrotik.delete_router(router)

    {:noreply,
     socket |> put_flash(:info, "Roteador excluído.") |> assign(:routers, Mikrotik.list_routers())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header>
        Roteadores
        <:actions>
          <.link patch={~p"/routers/new"} class="btn btn-aurora btn-sm">Novo Roteador</.link>
        </:actions>
      </.header>
      
      <table class="table">
        <thead>
          <tr>
            <th>Label</th>
            
            <th>URL</th>
            
            <th>Usuário</th>
            
            <th class="text-right">Ações</th>
          </tr>
        </thead>
        
        <tbody id="routers">
          <tr :for={router <- @routers} id={"router-#{router.id}"}>
            <td>{router.label}</td>
            
            <td>{router.url}</td>
            
            <td>{router.username}</td>
            
            <td class="text-right space-x-2">
              <.link navigate={~p"/routers/#{router.id}"} class="link">Ver</.link>
              <.link navigate={~p"/routers/#{router.id}/edit"} class="link">Editar</.link>
              <.link
                phx-click={JS.push("delete", value: %{id: router.id})}
                data-confirm="Excluir este roteador?"
                class="link link-error"
              >
                Excluir
              </.link>
            </td>
          </tr>
        </tbody>
      </table>
      
      <p :if={@routers == []} class="text-center opacity-60 py-12">
        Nenhum roteador cadastrado. <.link patch={~p"/routers/new"} class="link">Criar o primeiro</.link>.
      </p>
      
      <.modal :if={@live_action == :new} id="router-modal" show on_cancel={JS.patch(~p"/routers")}>
        <.live_component
          module={TelecoreWeb.RouterLive.FormComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          router={@router}
          patch={~p"/routers"}
        />
      </.modal>
    </Layouts.app>
    """
  end
end
