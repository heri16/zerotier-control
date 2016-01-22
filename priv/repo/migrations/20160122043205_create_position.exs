defmodule Zerotier.Repo.Migrations.CreatePosition do
  use Ecto.Migration

  def change do
    create table(:positions) do
      add :name, :string, null: false
      add :notes, :text
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps
    end
    create index(:positions, [:company_id])
    create unique_index(:positions, [:company_id, :name], name: :positions_company_id_name_index)

  end
end
