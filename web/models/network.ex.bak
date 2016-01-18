defmodule Zerotier.Network do
  use Zerotier.Web, :model

  @moduledoc """
  https://github.com/zerotier/ZeroTierOne/tree/master/service
  """

  @primary_key {:nwid, :string, []}
  @derive {Phoenix.Param, key: :nwid}
  schema "networks" do
    field :name, :string
    field :private, :boolean
    field :enableBroadcast, :boolean, virtual: true
    field :allowPassiveBridging, :boolean, virtual: true
    field :v4AssignMode, :string, virtual: true
    field :v6AssignMode, :string, virtual: true
    field :multicastLimit, :integer, virtual: true
    field :creationTime, :integer, virtual: true
    field :revision, :integer, virtual: true
    field :memberRevisionCounter, :integer, virtual: true
    field :clock, :integer, virtual: true
    field :authorizedMemberCount, :integer, virtual: true
    field :ipLocalRoutes, :any, virtual: true

    # :relays
    # :ipAssignmentPools
    # :rules

    timestamps
  end
end