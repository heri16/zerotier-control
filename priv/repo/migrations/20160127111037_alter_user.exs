defmodule Zerotier.Repo.Migrations.AlterUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
    end
    create index(:users, [:tenant_id])
    create unique_index(:users, [:tenant_id, :username], name: :users_tenant_id_username_index)

  end
end
