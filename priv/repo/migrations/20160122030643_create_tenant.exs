defmodule Zerotier.Repo.Migrations.CreateTenant do
  use Ecto.Migration

  def up do
    #execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""

    create table(:tenants, primary_key: false) do
      add :id, :uuid, primary_key: true  #, default: fragment("uuid_generate_v4()")
      add :name, :string, null: false

      timestamps
    end

  end

  def down do
    #execute "DROP EXTENSION IF EXISTS \"uuid-ossp\""

    drop table(:tenants)
  end
end
