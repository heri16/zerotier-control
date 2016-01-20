defmodule Zerotier.NetworkMemberControllerTest do
  use Zerotier.ConnCase

  alias Zerotier.NetworkMember
  @valid_attrs %{activeBridge: true, address: "some content", authorized: true, clock: 42, identity: "some content", ipAssignments: [], memberRevision: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, network_member_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing network members"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, network_member_path(conn, :new)
    assert html_response(conn, 200) =~ "New network member"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, network_member_path(conn, :create), network_member: @valid_attrs
    assert redirected_to(conn) == network_member_path(conn, :index)
    assert Repo.get_by(NetworkMember, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, network_member_path(conn, :create), network_member: @invalid_attrs
    assert html_response(conn, 200) =~ "New network member"
  end

  test "shows chosen resource", %{conn: conn} do
    network_member = Repo.insert! %NetworkMember{}
    conn = get conn, network_member_path(conn, :show, network_member)
    assert html_response(conn, 200) =~ "Show network member"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, network_member_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    network_member = Repo.insert! %NetworkMember{}
    conn = get conn, network_member_path(conn, :edit, network_member)
    assert html_response(conn, 200) =~ "Edit network member"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    network_member = Repo.insert! %NetworkMember{}
    conn = put conn, network_member_path(conn, :update, network_member), network_member: @valid_attrs
    assert redirected_to(conn) == network_member_path(conn, :show, network_member)
    assert Repo.get_by(NetworkMember, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    network_member = Repo.insert! %NetworkMember{}
    conn = put conn, network_member_path(conn, :update, network_member), network_member: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit network member"
  end

  test "deletes chosen resource", %{conn: conn} do
    network_member = Repo.insert! %NetworkMember{}
    conn = delete conn, network_member_path(conn, :delete, network_member)
    assert redirected_to(conn) == network_member_path(conn, :index)
    refute Repo.get(NetworkMember, network_member.id)
  end
end
