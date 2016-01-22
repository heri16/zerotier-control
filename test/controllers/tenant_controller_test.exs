defmodule Zerotier.TenantControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.Tenant
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, tenant_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing tenants"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, tenant_path(conn, :new)
    assert html_response(conn, 200) =~ "New tenant"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, tenant_path(conn, :create), tenant: @valid_attrs
    assert redirected_to(conn) == tenant_path(conn, :index)
    assert Repo.get_by(Tenant, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, tenant_path(conn, :create), tenant: @invalid_attrs
    assert html_response(conn, 200) =~ "New tenant"
  end

  test "shows chosen resource", %{conn: conn} do
    tenant = Repo.insert! %Tenant{}
    conn = get conn, tenant_path(conn, :show, tenant)
    assert html_response(conn, 200) =~ "Show tenant"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, tenant_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    tenant = Repo.insert! %Tenant{}
    conn = get conn, tenant_path(conn, :edit, tenant)
    assert html_response(conn, 200) =~ "Edit tenant"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    tenant = Repo.insert! %Tenant{}
    conn = put conn, tenant_path(conn, :update, tenant), tenant: @valid_attrs
    assert redirected_to(conn) == tenant_path(conn, :show, tenant)
    assert Repo.get_by(Tenant, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    tenant = Repo.insert! %Tenant{}
    conn = put conn, tenant_path(conn, :update, tenant), tenant: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit tenant"
  end

  test "deletes chosen resource", %{conn: conn} do
    tenant = Repo.insert! %Tenant{}
    conn = delete conn, tenant_path(conn, :delete, tenant)
    assert redirected_to(conn) == tenant_path(conn, :index)
    refute Repo.get(Tenant, tenant.id)
  end
end
