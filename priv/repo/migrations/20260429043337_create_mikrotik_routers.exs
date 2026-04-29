defmodule Telecore.Repo.Migrations.CreateMikrotikRouters do
  use Ecto.Migration

  def change do
    create table(:mikrotik_routers, primary_key: false) do
      add :id,       :binary_id, primary_key: true
      add :label,    :string, null: false
      add :url,      :string, null: false
      add :username, :string, null: false
      add :password, :binary, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
