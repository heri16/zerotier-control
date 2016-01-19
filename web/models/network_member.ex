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

  @required_fields ~w(nwid address authorized)
  @optional_fields ~w(activeBridge clock identity ipAssignments memberRevision)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:nwid, is: 16)
    |> validate_length(:address, is: 10)
    |> unique_constraint(:address, name: :network_members_nwid_address_index)
  end

end