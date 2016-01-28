defmodule Zerotier.Repo.Migrations.CreateCompany do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string, null: false
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false

      timestamps
    end
    create index(:companies, [:tenant_id])

  end
end
