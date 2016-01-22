defmodule Zerotier.Tenant do
  use Zerotier.Web, :model

  @primary_key {:id, Ecto.UUID, []}
  @foreign_key_type Ecto.UUID
  schema "tenants" do
    field :name, :string

    has_many :companies, Zerotier.Company

    timestamps
  end

  @required_fields ~w(name)
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

  def creation_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> Ecto.Changeset.put_change(:id, Ecto.UUID.generate())
  end
end
