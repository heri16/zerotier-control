defmodule Zerotier.Repo.Migrations.CreateDepartment do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :string, null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps
    end
    create index(:departments, [:company_id])
    create unique_index(:departments, [:company_id, :name], name: :departments_company_id_name_index)

  end
end
