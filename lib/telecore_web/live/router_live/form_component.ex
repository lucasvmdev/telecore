defmodule TelecoreWeb.RouterLive.FormComponent do
  use TelecoreWeb, :live_component

  alias Telecore.Mikrotik
  alias Telecore.Mikrotik.Router

  @impl true
  def update(%{router: router} = assigns, socket) do
    changeset = Router.changeset(router, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:test_status, nil)}
  end

  @impl true
  def handle_event("validate", %{"router" => params}, socket) do
    changeset =
      socket.assigns.router
      |> Router.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"router" => params}, socket) do
    save(socket, socket.assigns.action, params)
  end

  def handle_event("test_connection", %{"router" => params}, socket) do
    changeset = Router.changeset(socket.assigns.router, params)

    if changeset.valid? do
      router = Ecto.Changeset.apply_changes(changeset)

      result = Mikrotik.list_secrets(router)

      status =
        case result do
          {:ok, _} -> {:ok, "Conexão OK."}
          {:error, %{code: code, message: msg}} -> {:error, "#{code}: #{msg}"}
        end

      {:noreply, assign(socket, :test_status, status)}
    else
      {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
    end
  end

  defp save(socket, :new, params) do
    case Mikrotik.create_router(params) do
      {:ok, router} ->
        notify_parent({:saved, router})

        {:noreply,
         socket
         |> put_flash(:info, "Roteador criado.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign_form(socket, cs)}
    end
  end

  defp save(socket, :edit, params) do
    case Mikrotik.update_router(socket.assigns.router, params) do
      {:ok, router} ->
        notify_parent({:saved, router})

        {:noreply,
         socket
         |> put_flash(:info, "Roteador atualizado.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign_form(socket, cs)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = cs) do
    assign(socket, :form, to_form(cs))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="router-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:label]} type="text" label="Label (POP/identificador)" />
        <.input field={@form[:url]} type="text" label="URL (https://...)" />
        <.input field={@form[:username]} type="text" label="Usuário" />
        <.input field={@form[:password]} type="password" label="Senha" />

        <div :if={@test_status}>
          <div :if={match?({:ok, _}, @test_status)} class="alert alert-success">
            {elem(@test_status, 1)}
          </div>
          <div :if={match?({:error, _}, @test_status)} class="alert alert-error">
            {elem(@test_status, 1)}
          </div>
        </div>

        <:actions>
          <.button phx-target={@myself} phx-click="test_connection" type="button" class="btn-ghost">
            Testar conexão
          </.button>
          <.button phx-disable-with="Salvando..." type="submit">Salvar</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
