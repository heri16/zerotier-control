defmodule Zerotier.NetworkMemberTest do
  use Zerotier.ModelCase

  alias Zerotier.NetworkMember

  @valid_attrs %{activeBridge: true, address: "some content", authorized: true, clock: 42, identity: "some content", ipAssignments: [], memberRevision: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = NetworkMember.changeset(%NetworkMember{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = NetworkMember.changeset(%NetworkMember{}, @invalid_attrs)
    refute changeset.valid?
  end
end
