defmodule Zerotier.Repo.Migrations.CreateNetwork do
  use Ecto.Migration

  def change do
    create table(:networks, primary_key: false) do
      add :nwid, :string, primary_key: true
      add :name, :string
      add :private, :boolean, default: false
      add :ipAssignmentPools, {:array, :map}, default: []
      add :rules, {:array, :map}, default: []
      add :relays, {:array, :map}, default: []

      timestamps
    end

  end
end
