defmodule Telecore.Mikrotik.SecretForm do
  @moduledoc """
  Embedded schema for the secret create/edit form. Bridges between the
  string-keyed maps the Mikrotik adapter speaks and the typed Ecto changeset
  the LiveView form needs.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :password, :string
    field :profile, :string
    field :service, :string, default: "pppoe"
    field :comment, :string
  end

  @required ~w(name password profile)a
  @cast ~w(name password profile service comment)a

  def changeset(form \\ %__MODULE__{}, attrs) do
    form
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> validate_format(:name, ~r/^[a-zA-Z0-9._-]+$/, message: "must be alphanumeric (._- allowed)")
  end

  def to_attrs(%__MODULE__{} = f) do
    %{
      "name" => f.name,
      "password" => f.password,
      "profile" => f.profile,
      "service" => f.service || "pppoe",
      "comment" => f.comment || ""
    }
  end

  def from_secret(secret) when is_map(secret) do
    %__MODULE__{
      name: secret["name"],
      password: secret["password"],
      profile: secret["profile"],
      service: secret["service"] || "pppoe",
      comment: secret["comment"]
    }
  end
end
