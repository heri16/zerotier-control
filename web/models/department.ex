defmodule Zerotier.Department do
  use Zerotier.Web, :model

  schema "departments" do
    field :name, :string
    belongs_to :company, Zerotier.Company

    timestamps
  end

  @required_fields ~w(name company_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name, name: :departments_company_id_name_index)
    |> foreign_key_constraint(:company_id)
  end
end
