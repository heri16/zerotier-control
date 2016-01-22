defmodule Zerotier.DepartmentControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.Department
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, department_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing departments"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, department_path(conn, :new)
    assert html_response(conn, 200) =~ "New department"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, department_path(conn, :create), department: @valid_attrs
    assert redirected_to(conn) == department_path(conn, :index)
    assert Repo.get_by(Department, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, department_path(conn, :create), department: @invalid_attrs
    assert html_response(conn, 200) =~ "New department"
  end

  test "shows chosen resource", %{conn: conn} do
    department = Repo.insert! %Department{}
    conn = get conn, department_path(conn, :show, department)
    assert html_response(conn, 200) =~ "Show department"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, department_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    department = Repo.insert! %Department{}
    conn = get conn, department_path(conn, :edit, department)
    assert html_response(conn, 200) =~ "Edit department"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    department = Repo.insert! %Department{}
    conn = put conn, department_path(conn, :update, department), department: @valid_attrs
    assert redirected_to(conn) == department_path(conn, :show, department)
    assert Repo.get_by(Department, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    department = Repo.insert! %Department{}
    conn = put conn, department_path(conn, :update, department), department: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit department"
  end

  test "deletes chosen resource", %{conn: conn} do
    department = Repo.insert! %Department{}
    conn = delete conn, department_path(conn, :delete, department)
    assert redirected_to(conn) == department_path(conn, :index)
    refute Repo.get(Department, department.id)
  end
end
