defmodule Zerotier.OfficeControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.Office
  @valid_attrs %{location: "some content", name: "some content", type: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, office_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing offices"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, office_path(conn, :new)
    assert html_response(conn, 200) =~ "New office"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, office_path(conn, :create), office: @valid_attrs
    assert redirected_to(conn) == office_path(conn, :index)
    assert Repo.get_by(Office, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, office_path(conn, :create), office: @invalid_attrs
    assert html_response(conn, 200) =~ "New office"
  end

  test "shows chosen resource", %{conn: conn} do
    office = Repo.insert! %Office{}
    conn = get conn, office_path(conn, :show, office)
    assert html_response(conn, 200) =~ "Show office"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, office_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    office = Repo.insert! %Office{}
    conn = get conn, office_path(conn, :edit, office)
    assert html_response(conn, 200) =~ "Edit office"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    office = Repo.insert! %Office{}
    conn = put conn, office_path(conn, :update, office), office: @valid_attrs
    assert redirected_to(conn) == office_path(conn, :show, office)
    assert Repo.get_by(Office, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    office = Repo.insert! %Office{}
    conn = put conn, office_path(conn, :update, office), office: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit office"
  end

  test "deletes chosen resource", %{conn: conn} do
    office = Repo.insert! %Office{}
    conn = delete conn, office_path(conn, :delete, office)
    assert redirected_to(conn) == office_path(conn, :index)
    refute Repo.get(Office, office.id)
  end
end
