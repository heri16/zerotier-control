defmodule Zerotier.NetworkMember do
  use Zerotier.Web, :model
  #import Ecto.Changeset

  # Note: Struct is automatically defined
  #defstruct [:nwid, :address]

  # Note: Primary key is automatically defined
  schema "network_members" do
    field :nwid, :string
    field :address, :string
    field :authorized, :boolean, virtual: true
    field :activeBridge, :boolean, virtual: true
    field :clock, :integer, virtual: true
    field :identity, :string, virtual: true
    field :ipAssignments, :any, virtual: true
    field :memberRevision, :integer, virtual: true
  
    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(nwid address authorized), [])
    |> validate_length(:nwid, is: 16)
    |> validate_length(:address, is: 10)
    |> unique_constraint(:address, name: :network_members_nwid_address_index)
    |> check_with_backend
  end

  def check_with_backend(changeset) do
    # First check changeset is valid, so we won't waste time hashing an invalid.
    case changeset do
      %{valid?: true, changes: %{address: _address}} ->
        #Zerotier.One.Controller.authorize_network_member(nwid, address, "crm3h7bXRwfrg1LGra06b5zc")
        changeset
      _ ->
        # If changeset not valid, simply return to caller
        changeset
    end
  end

  def update_with_unsafe_map(model, %{"authorized" => authorized, "activeBridge" => activeBridge, "clock" => clock, "identity" => identity, "ipAssignments" => ipAssignments, "memberRevision" => memberRevision}) do
    %{ model |  authorized: authorized, activeBridge: activeBridge, clock: clock, identity: identity, ipAssignments: ipAssignments, memberRevision: memberRevision }
  end
end