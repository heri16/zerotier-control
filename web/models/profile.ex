defmodule Zerotier.Profile do
  use Zerotier.Web, :model

  schema "profiles" do
    field :name, :string
    field :notes, :string
    belongs_to :office, Zerotier.Office
    belongs_to :department, Zerotier.Department
    belongs_to :position, Zerotier.Position
    belongs_to :user, Zerotier.User

    has_many :network_members, Zerotier.NetworkMember

    timestamps
  end

  @required_fields ~w(name office_id department_id position_id user_id)
  @optional_fields ~w(notes)

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
