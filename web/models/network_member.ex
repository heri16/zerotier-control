defmodule Zerotier.NetworkMember do
  use Zerotier.Web, :model

  @writable_json_fields ~w(authorized activeBridge ipAssignments)a

  @derive {Poison.Encoder, only: @writable_json_fields}
  schema "network_members" do
    field :address, :string
    field :authorized, :boolean, default: false
    field :activeBridge, :boolean, default: false
    field :clock, :integer, virtual: true
    field :identity, :string, virtual: true
    field :memberRevision, :integer, virtual: true
    field :ipAssignments, {:array, :string}
    field :recentLog, {:array, :map}, virtual: true
    belongs_to :network, Zerotier.Network, foreign_key: :nwid, references: :nwid, type: :string

    timestamps
  end

  @required_fields ~w(nwid address authorized activeBridge ipAssignments)
  @optional_fields ~w(clock identity memberRevision recentLog)

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
    |> foreign_key_constraint(:nwid)
  end

  def deserialization_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
  end

end
