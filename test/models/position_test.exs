defmodule Zerotier.PositionTest do
  use Zerotier.ModelCase

  alias Zerotier.Position

  @valid_attrs %{name: "some content", notes: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Position.changeset(%Position{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Position.changeset(%Position{}, @invalid_attrs)
    refute changeset.valid?
  end
end
