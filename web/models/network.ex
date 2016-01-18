defmodule Zerotier.Network do
  use Zerotier.Web, :model

  @moduledoc """
  https://github.com/zerotier/ZeroTierOne/tree/master/service
  """

  @primary_key {:nwid, :string, []}
  @derive {Phoenix.Param, key: :nwid}
  schema "networks" do
    field :name, :string
    field :private, :boolean, default: false
    field :enableBroadcast, :boolean, default: false, virtual: true
    field :allowPassiveBridging, :boolean, default: false, virtual: true
    field :v4AssignMode, :string, virtual: true
    field :v6AssignMode, :string, virtual: true
    field :multicastLimit, :integer, virtual: true
    field :creationTime, :integer, virtual: true
    field :revision, :integer, virtual: true
    field :memberRevisionCounter, :integer, virtual: true
    field :clock, :integer, virtual: true
    field :authorizedMemberCount, :integer, virtual: true

    timestamps
  end

  @required_fields ~w(name private)
  @optional_fields ~w(enableBroadcast allowPassiveBridging v4AssignMode v6AssignMode multicastLimit creationTime revision memberRevisionCounter clock authorizedMemberCount)

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
