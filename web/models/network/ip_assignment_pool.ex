defmodule Zerotier.Network.IpAssignmentPool do
  use Zerotier.Web, :model

  @derive {Poison.Encoder, only: [:ipRangeStart, :ipRangeEnd]}
  embedded_schema do
    field :ipRangeStart, :string, virtual: true
    field :ipRangeEnd, :string, virtual: true

    timestamps
  end

  @required_fields ~w(ipRangeStart ipRangeEnd)
  @optional_fields ~w()

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