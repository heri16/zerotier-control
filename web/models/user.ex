defmodule Zerotier.User do
  use Zerotier.Web, :model

  # Note: Struct is automatically defined
  #defstruct [:id, :name, :username, :password]

  # Note: Primary key is automatically defined
  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    belongs_to :tenant, Zerotier.Tenant, type: Ecto.UUID

    has_many :profiles, Zerotier.Profile

    timestamps
  end

  @required_fields ~w(name username tenant_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    # Pass :empty to Ecto for a blank new changeset
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:username, min: 4, max: 20)
    |> unique_constraint(:username, name: :users_tenant_id_username_index)
    |> foreign_key_constraint(:tenant_id)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_length(:password, min: 10, max: 100)
    |> put_pass_hash()
  end

  def put_pass_hash(changeset) do
    # First check changeset is valid, so we won't waste time hashing an invalid.
    case changeset do
      %{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        # If changeset not valid, simply return to caller
        changeset
    end
  end

end
