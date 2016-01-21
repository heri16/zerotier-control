defmodule Zerotier.Network.Rule do
  use Zerotier.Web, :model

  @derive {Poison.Encoder, only: [:ruleNo, :etherType, :action]}
  embedded_schema do
    field :ruleNo, :integer, virtual: true
    field :nodeId, :string, virtual: true
    field :sourcePort, :string, virtual: true
    field :destPort, :string, virtual: true
    field :vlanId, :integer, virtual: true
    field :vlanPcp, :integer, virtual: true
    field :etherType, :integer, virtual: true
    field :macSource, :string, virtual: true
    field :macDest, :string, virtual: true
    field :ipSource, :string, virtual: true
    field :ipDest, :string, virtual: true
    field :ipTos, :integer, virtual: true
    field :ipProtocol, :integer, virtual: true
    field :ipSourcePort, :integer, virtual: true
    field :ipDestPort, :integer, virtual: true
    field :action, :string, virtual: true

    timestamps
  end

  @required_fields ~w(ruleNo etherType action)
  @optional_fields ~w(
      nodeId sourcePort destPort vlanId vlanPcp etherType macSource macDest
      ipSource ipDest ipTos ipProtocol ipSourcePort ipDestPort
    )

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
