defmodule Zerotier.TenantTest do
  use Zerotier.ModelCase

  alias Zerotier.Tenant

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Tenant.changeset(%Tenant{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Tenant.changeset(%Tenant{}, @invalid_attrs)
    refute changeset.valid?
  end
end
