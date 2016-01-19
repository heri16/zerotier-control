defmodule Zerotier.Repo.Migrations.CreateNetworkMember do
  use Ecto.Migration

  def change do
    create table(:network_members) do
      add :nwid, :string, null: false
      add :address, :string, null: false

      timestamps
    end

    create unique_index(:network_members, [:nwid, :address], name: :network_members_nwid_address_index)
  end
end
