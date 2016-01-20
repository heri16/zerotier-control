defmodule Zerotier.Repo.Migrations.CreateNetworkMember do
  use Ecto.Migration

  def change do
    create table(:network_members) do
      add :address, :string, size: 10
      add :authorized, :boolean, default: false
      add :activeBridge, :boolean, default: false
      add :ipAssignments, {:array, :string}
      add :nwid, references(:networks, column: :nwid, type: :string, on_delete: :nothing), size: 16

      timestamps
    end
    create index(:network_members, [:nwid])
    create unique_index(:network_members, [:nwid, :address], name: :network_members_nwid_address_index)

  end
end
