defmodule TelecoreWeb.SecretLive.FormComponent do
  use TelecoreWeb, :live_component

  alias Telecore.Mikrotik
  alias Telecore.Mikrotik.SecretForm

  @impl true
  def update(%{secret_form: form} = assigns, socket) do
    changeset = SecretForm.changeset(form, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"secret_form" => params}, socket) do
    changeset =
      socket.assigns.secret_form
      |> SecretForm.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"secret_form" => params}, socket) do
    changeset =
      socket.assigns.secret_form
      |> SecretForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      attrs = changeset |> Ecto.Changeset.apply_changes() |> SecretForm.to_attrs()
      do_save(socket, socket.assigns.action, attrs)
    else
      {:noreply, assign_form(socket, changeset)}
    end
  end

  defp do_save(socket, :new, attrs) do
    case Mikrotik.create_secret(socket.assigns.router, attrs) do
      {:ok, _} ->
        notify_parent(:saved)
        {:noreply, socket |> put_flash(:info, "Cliente criado.") |> push_patch(to: socket.assigns.patch)}

      {:error, %{message: m}} ->
        {:noreply, put_flash(socket, :error, "Falha: #{m}")}
    end
  end

  defp do_save(socket, :edit, attrs) do
    case Mikrotik.update_secret(socket.assigns.router, socket.assigns.secret_name, attrs) do
      {:ok, _} ->
        notify_parent(:saved)
        {:noreply, socket |> put_flash(:info, "Cliente atualizado.") |> push_patch(to: socket.assigns.patch)}

      {:error, %{message: m}} ->
        {:noreply, put_flash(socket, :error, "Falha: #{m}")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = cs), do: assign(socket, :form, to_form(cs))

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>

      <.simple_form
        for={@form}
        id="secret-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Nome (login PPPoE)" />
        <.input field={@form[:password]} type="text" label="Senha" />
        <.input field={@form[:profile]} type="text" label="Profile (ex.: 10mbps)" />
        <.input field={@form[:service]} type="text" label="Service" />
        <.input field={@form[:comment]} type="text" label="Observação" />

        <:actions>
          <.button phx-disable-with="Salvando..." type="submit">Salvar</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
