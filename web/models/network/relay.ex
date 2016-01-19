defmodule Zerotier.Network.Relay do
  use Zerotier.Web, :model

  @derive {Poison.Encoder, only: [:address, :phyAddress]}
  embedded_schema do
    field :address, :string, virtual: true
    field :phyAddress, :string, virtual: true

    timestamps
  end

  @required_fields ~w(address phyAddress)
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
