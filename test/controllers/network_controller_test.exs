defmodule Zerotier.NetworkControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.Network
  @valid_attrs %{allowPassiveBridging: true, authorizedMemberCount: 42, clock: 42, creationTime: 42, enableBroadcast: true, memberRevisionCounter: 42, multicastLimit: 42, name: "some content", private: true, revision: 42, v4AssignMode: "some content", v6AssignMode: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, network_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing networks"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, network_path(conn, :new)
    assert html_response(conn, 200) =~ "New network"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, network_path(conn, :create), network: @valid_attrs
    assert redirected_to(conn) == network_path(conn, :index)
    assert Repo.get_by(Network, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, network_path(conn, :create), network: @invalid_attrs
    assert html_response(conn, 200) =~ "New network"
  end

  test "shows chosen resource", %{conn: conn} do
    network = Repo.insert! %Network{}
    conn = get conn, network_path(conn, :show, network)
    assert html_response(conn, 200) =~ "Show network"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, network_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    network = Repo.insert! %Network{}
    conn = get conn, network_path(conn, :edit, network)
    assert html_response(conn, 200) =~ "Edit network"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    network = Repo.insert! %Network{}
    conn = put conn, network_path(conn, :update, network), network: @valid_attrs
    assert redirected_to(conn) == network_path(conn, :show, network)
    assert Repo.get_by(Network, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    network = Repo.insert! %Network{}
    conn = put conn, network_path(conn, :update, network), network: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit network"
  end

  test "deletes chosen resource", %{conn: conn} do
    network = Repo.insert! %Network{}
    conn = delete conn, network_path(conn, :delete, network)
    assert redirected_to(conn) == network_path(conn, :index)
    refute Repo.get(Network, network.id)
  end
end
