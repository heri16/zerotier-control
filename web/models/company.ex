defmodule Zerotier.Company do
  use Zerotier.Web, :model

  schema "companies" do
    field :name, :string
    belongs_to :tenant, Zerotier.Tenant, type: Ecto.UUID

    has_many :offices, Zerotier.Office
    has_many :departments, Zerotier.Department
    has_many :positions, Zerotier.Position

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
end
