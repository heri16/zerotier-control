defmodule Zerotier.OfficeTest do
  use Zerotier.ModelCase

  alias Zerotier.Office

  @valid_attrs %{location: "some content", name: "some content", type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Office.changeset(%Office{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Office.changeset(%Office{}, @invalid_attrs)
    refute changeset.valid?
  end
end
