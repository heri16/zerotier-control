defmodule Zerotier.Repo.Migrations.CreateOffice do
  use Ecto.Migration

  def change do
    create table(:offices) do
      add :name, :string, null: false
      add :location, :string
      add :type, :string
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps
    end
    create index(:offices, [:company_id])
    create unique_index(:offices, [:company_id, :name], name: :offices_company_id_name_index)

  end
end
