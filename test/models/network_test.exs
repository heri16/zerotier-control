defmodule Zerotier.NetworkTest do
  use Zerotier.ModelCase

  alias Zerotier.Network

  @valid_attrs %{allowPassiveBridging: true, authorizedMemberCount: 42, clock: 42, creationTime: 42, enableBroadcast: true, memberRevisionCounter: 42, multicastLimit: 42, name: "some content", private: true, revision: 42, v4AssignMode: "some content", v6AssignMode: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Network.changeset(%Network{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Network.changeset(%Network{}, @invalid_attrs)
    refute changeset.valid?
  end
end
