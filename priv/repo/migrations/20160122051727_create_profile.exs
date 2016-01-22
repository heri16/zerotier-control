defmodule Zerotier.Repo.Migrations.CreateProfile do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :name, :string, null: false
      add :notes, :text
      add :office_id, references(:offices, on_delete: :nothing)
      add :department_id, references(:departments, on_delete: :nothing)
      add :position_id, references(:positions, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps
    end
    create index(:profiles, [:office_id])
    create index(:profiles, [:department_id])
    create index(:profiles, [:position_id])
    create index(:profiles, [:user_id])

  end
end
