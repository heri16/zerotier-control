defmodule Zerotier.PositionControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.Position
  @valid_attrs %{name: "some content", notes: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, position_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing positions"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, position_path(conn, :new)
    assert html_response(conn, 200) =~ "New position"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, position_path(conn, :create), position: @valid_attrs
    assert redirected_to(conn) == position_path(conn, :index)
    assert Repo.get_by(Position, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, position_path(conn, :create), position: @invalid_attrs
    assert html_response(conn, 200) =~ "New position"
  end

  test "shows chosen resource", %{conn: conn} do
    position = Repo.insert! %Position{}
    conn = get conn, position_path(conn, :show, position)
    assert html_response(conn, 200) =~ "Show position"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, position_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    position = Repo.insert! %Position{}
    conn = get conn, position_path(conn, :edit, position)
    assert html_response(conn, 200) =~ "Edit position"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    position = Repo.insert! %Position{}
    conn = put conn, position_path(conn, :update, position), position: @valid_attrs
    assert redirected_to(conn) == position_path(conn, :show, position)
    assert Repo.get_by(Position, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    position = Repo.insert! %Position{}
    conn = put conn, position_path(conn, :update, position), position: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit position"
  end

  test "deletes chosen resource", %{conn: conn} do
    position = Repo.insert! %Position{}
    conn = delete conn, position_path(conn, :delete, position)
    assert redirected_to(conn) == position_path(conn, :index)
    refute Repo.get(Position, position.id)
  end
end
