defmodule Telecore.Mikrotik.Router do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mikrotik_routers" do
    field :label,    :string
    field :url,      :string
    field :username, :string
    field :password, Telecore.Encrypted.Binary

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(label url username password)a

  def changeset(router, attrs) do
    router
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_format(:url, ~r/^https?:\/\//)
  end
end
