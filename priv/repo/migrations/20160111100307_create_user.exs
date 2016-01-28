defmodule Zerotier.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :username, :string, null: false
      add :password_hash, :string
      #add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false

      timestamps
    end
    #create index(:companies, [:tenant_id])
    #create unique_index(:users, [:tenant_id, :username], name: :users_tenant_id_username_index)

  end
end
