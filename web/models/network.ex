defmodule Zerotier.Network do
  use Zerotier.Web, :model

  @moduledoc """
  ZeroTierOne Network Model

  See: https://github.com/zerotier/ZeroTierOne/tree/master/service
  """

  @required_fields ~w(nwid name private enableBroadcast allowPassiveBridging v4AssignMode v6AssignMode multicastLimit relays ipLocalRoutes ipAssignmentPools rules)
  @optional_fields ~w(creationTime clock revision memberRevisionCounter authorizedMemberCount)
  @embeds_many_fields ~w(ipAssignmentPools rules relays)a
  @writable_json_fields ~w(name private enableBroadcast allowPassiveBridging v4AssignMode v6AssignMode multicastLimit relays ipLocalRoutes ipAssignmentPools rules)a

  @v4_assign_modes ["none", "zt", "dhcp"]
  @v6_assign_modes ["none", "zt", "rfc4193", "dhcp"]

  @primary_key {:nwid, :string, []}
  @derive {Phoenix.Param, key: :nwid}
  @derive {Poison.Encoder, only: @writable_json_fields}
  schema "networks" do
    field :name, :string
    field :private, :boolean, default: true
    field :enableBroadcast, :boolean, default: false, virtual: true
    field :allowPassiveBridging, :boolean, default: false, virtual: true
    field :v4AssignMode, :string, default: "none", virtual: true
    field :v6AssignMode, :string, default: "none", virtual: true
    field :multicastLimit, :integer, default: 32, virtual: true
    field :creationTime, :integer, virtual: true
    field :clock, :integer, virtual: true
    field :revision, :integer, virtual: true
    field :memberRevisionCounter, :integer, virtual: true
    field :authorizedMemberCount, :integer, virtual: true

    field :ipLocalRoutes, {:array, :string}, virtual: true
    embeds_many :ipAssignmentPools, Zerotier.Network.IpAssignmentPool, on_replace: :mark_as_invalid
    embeds_many :rules, Zerotier.Network.Rule, on_replace: :mark_as_invalid
    embeds_many :relays, Zerotier.Network.Relay, on_replace: :mark_as_invalid

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> cast_embed(:ipAssignmentPools, required: true)
    |> cast_embed(:rules, required: false)
    |> cast_embed(:relays, required: false)
    |> validate_inclusion(:v4AssignMode, @v4_assign_modes)
    |> validate_inclusion(:v4AssignMode, @v6_assign_modes)
    |> validate_length(:nwid, is: 16)
    |> validate_length(:ipLocalRoutes, min: 1)
    |> validate_number(:multicastLimit, greater_than: 0)
    |> unique_constraint(:nwid, name: :networks_pkey)
  end

  def deserialization_changeset(model, params \\ :empty) do
    # Workaround for embeds_many/3 (on_replace: :mark_as_invalid)
    # by populating the id of all embeds nested in params
    populated_params = params_populate_embeds_ids(params, model)

    model
    |> changeset(populated_params)
  end

  @doc """
  Populates "id" field of all embedded objects nested inside params.
  """
  @spec params_populate_embeds_ids(%{ String.t => String.t }, Ecto.Schema.t) :: map
  def params_populate_embeds_ids(params = :empty, _model), do: params
  def params_populate_embeds_ids(params, model) do
    @embeds_many_fields
    #|> Enum.map(&String.to_atom/1)
    |> Enum.reduce(params, &params_populate_embeds_ids(&2, model, &1))
  end

  @doc """
  Populates "id" field of embedded objects nested inside one single field of params.
  """
  @spec params_populate_embeds_ids(%{ String.t => String.t }, Ecto.Schema.t, atom) :: map
  def params_populate_embeds_ids(params, model, field) when is_atom(field) do
    # Pattern-match the embeds_many field from the model
    %{^field => model_embeds} = model

    # An embeds_many field is a list nested inside the params
    # Restore the "id" field to all objects inside this list
    params
    |> Map.update(Atom.to_string(field), [], fn embeds_many_params ->
        embeds_many_params |> Enum.with_index |> Enum.map(fn {each_embed, index} -> 
          case Enum.fetch(model_embeds, index) do
            {:ok, _emb = %{id: id} } -> each_embed |> Map.put_new("id", id)
            :error -> each_embed
          end
        end)
      end)
  end

end
