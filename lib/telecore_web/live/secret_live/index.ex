defmodule TelecoreWeb.SecretLive.Index do
  use TelecoreWeb, :live_view

  alias Telecore.Mikrotik
  alias Telecore.Mikrotik.SecretForm

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    router = Mikrotik.get_router!(id)

    {:ok,
     socket
     |> assign(:router, router)
     |> load_secrets()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Clientes — #{socket.assigns.router.label}")
    |> assign(:secret_form, nil)
    |> assign(:secret_name, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Novo cliente")
    |> assign(:secret_form, %SecretForm{})
    |> assign(:secret_name, nil)
  end

  defp apply_action(socket, :edit, %{"name" => name}) do
    case Mikrotik.get_secret(socket.assigns.router, name) do
      {:ok, secret} ->
        socket
        |> assign(:page_title, "Editar #{name}")
        |> assign(:secret_form, SecretForm.from_secret(secret))
        |> assign(:secret_name, name)

      {:error, %{message: m}} ->
        socket
        |> put_flash(:error, "Cliente não encontrado: #{m}")
        |> push_navigate(to: ~p"/routers/#{socket.assigns.router.id}/secrets")
    end
  end

  @impl true
  def handle_info({TelecoreWeb.SecretLive.FormComponent, :saved}, socket) do
    {:noreply, load_secrets(socket)}
  end

  @impl true
  def handle_event("toggle", %{"name" => name, "disabled" => "true"}, socket) do
    case Mikrotik.enable_secret(socket.assigns.router, name) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "#{name} habilitado.") |> load_secrets()}
      {:error, %{message: m}} -> {:noreply, put_flash(socket, :error, m)}
    end
  end

  def handle_event("toggle", %{"name" => name, "disabled" => "false"}, socket) do
    case Mikrotik.disable_secret(socket.assigns.router, name) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "#{name} desabilitado.") |> load_secrets()}
      {:error, %{message: m}} -> {:noreply, put_flash(socket, :error, m)}
    end
  end

  def handle_event("delete", %{"name" => name}, socket) do
    case Mikrotik.delete_secret(socket.assigns.router, name) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "#{name} removido.") |> load_secrets()}
      {:error, %{message: m}} -> {:noreply, put_flash(socket, :error, m)}
    end
  end

  defp load_secrets(socket) do
    case Mikrotik.list_secrets(socket.assigns.router) do
      {:ok, secrets} -> assign(socket, secrets: secrets, last_error: nil)
      {:error, %{} = e} -> assign(socket, secrets: [], last_error: e)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.router_nav router={@router} active={:secrets} />

      <.header>
        Clientes (PPPoE secrets)
        <:actions>
          <.link patch={~p"/routers/#{@router.id}/secrets/new"} class="btn btn-aurora btn-sm">
            Novo cliente
          </.link>
        </:actions>
      </.header>

      <div :if={@last_error} class="alert alert-error">
        <span>Erro: {@last_error.message}</span>
      </div>

      <table class="table">
        <thead>
          <tr>
            <th>Nome</th>
            <th>Profile</th>
            <th>Service</th>
            <th>Status</th>
            <th class="text-right">Ações</th>
          </tr>
        </thead>
        <tbody id="secrets">
          <tr :for={s <- @secrets} id={"secret-#{s["name"]}"}>
            <td>{s["name"]}</td>
            <td>{s["profile"]}</td>
            <td>{s["service"]}</td>
            <td>
              <span :if={s["disabled"] == "true"} class="badge badge-ghost">Desabilitado</span>
              <span :if={s["disabled"] != "true"} class="badge badge-success">Habilitado</span>
            </td>
            <td class="text-right space-x-2">
              <.link patch={~p"/routers/#{@router.id}/secrets/#{s["name"]}/edit"} class="link">
                Editar
              </.link>
              <.link
                phx-click={JS.push("toggle", value: %{name: s["name"], disabled: s["disabled"] || "false"})}
                class="link"
              >
                {if s["disabled"] == "true", do: "Habilitar", else: "Desabilitar"}
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{name: s["name"]})}
                data-confirm={"Excluir #{s["name"]}?"}
                class="link link-error"
              >
                Excluir
              </.link>
            </td>
          </tr>
        </tbody>
      </table>

      <p :if={@secrets == [] and is_nil(@last_error)} class="text-center opacity-60 py-12">
        Nenhum cliente cadastrado neste roteador.
      </p>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="secret-modal"
        show
        on_cancel={JS.patch(~p"/routers/#{@router.id}/secrets")}
      >
        <.live_component
          module={TelecoreWeb.SecretLive.FormComponent}
          id={@secret_name || :new}
          title={@page_title}
          action={@live_action}
          router={@router}
          secret_form={@secret_form}
          secret_name={@secret_name}
          patch={~p"/routers/#{@router.id}/secrets"}
        />
      </.modal>
    </Layouts.app>
    """
  end
end
