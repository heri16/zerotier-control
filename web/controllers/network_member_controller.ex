defmodule Zerotier.NetworkMemberController do
  use Zerotier.Web, :controller
  alias Zerotier.NetworkMember

  plug :authenticate when action in [:index, :show, :new, :create, :delete]

  def index(conn, %{"nwid" => nwid}) when is_binary(nwid) do
    backend_task = Task.async(fn -> index_backend(%{nwid: nwid}) end)
    network_members = Repo.all(from m in NetworkMember, where: m.nwid == ^nwid)

    valid_network_members = case Task.yield(backend_task, 5000) do
      {:ok, members} ->
        network_members
        |> Enum.filter(fn m -> Enum.any?(members, &(&1 == m.address)) end)
      _ ->
        network_members
    end

    render(conn, "index.html", network_members: valid_network_members)
  end
  def index(conn, _) do
    network_members = Repo.all(NetworkMember)
    render(conn, "index.html", network_members: network_members)
  end

  def show(conn, %{"id" => id}) do
    network_member = Repo.get(Zerotier.NetworkMember, id)
    backend_task = Task.async(fn -> fetch_backend(network_member) end)

    loaded_network_member = case Task.yield(backend_task, 5000) do
      {:ok, backend_network_member = %{} } ->
        case network_member |>  NetworkMember.changeset(backend_network_member) do
          valid_changeset = %{valid?: true} ->
            valid_changeset |> Ecto.Changeset.apply_changes
          invalid_changeset ->
            IO.inspect(invalid_changeset)
            network_member
        end
      _ ->
        network_member 
    end

    IO.inspect loaded_network_member

    render(conn, "show.html", network_member: loaded_network_member)
  end

  def new(conn, %{"nwid" => nwid}) do
    changeset = NetworkMember.changeset(%NetworkMember{nwid: nwid})
    render(conn, "new.html", changeset: changeset)
  end
  def new(conn, _) do
    changeset = NetworkMember.changeset(%NetworkMember{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network_member" => network_member_params}) do
    # Recreate changeset from POST data
    changeset = NetworkMember.changeset(%NetworkMember{}, network_member_params)

    backend_task = Task.async(fn -> update_backend(changeset) end)

    case Repo.insert(changeset) do
      {:ok, network_member} ->
        # On Repo Success:
        case Task.yield(backend_task, 5000) do
          {:ok, {:ok, _backend_network_member}} ->
            # On Backend Sucess:
            conn
            |> put_flash(:info, "Node #{network_member.address} has been added to network #{network_member.nwid}!")
            |> redirect(to: network_member_path(conn, :index))

          {:ok, {:error, changeset, reason}} -> 
            # On Backend Error:
            Repo.delete(network_member)
            conn
            |> put_flash(:error, reason)
            |> render("new.html", changeset: changeset)

          _ ->
            # On Backend Task still running after timeout:
            conn
            |> put_flash(:error, "Backend Timeout")
            |> render("new.html", changeset: changeset)
        end
        
      {:error, changeset} ->
        # On Validation/Repo Error:
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, _opts) do
    conn
    |> put_flash(:info, "Authorization removed")
    |> redirect(to: page_path(conn, :index))
  end

  def index_backend(%{ nwid: nwid }) do
    Zerotier.One.Controller.list_network_members(nwid)
  end

  def fetch_backend(%{ nwid: nwid, address: address }) do
    Zerotier.One.Controller.fetch_network_member(nwid, address)
  end

  def update_backend(changeset) do
    IO.inspect changeset
    case changeset do
      %{valid?: true, changes: %{ nwid: nwid, address: address, authorized: true }} ->
        Zerotier.One.Controller.authorize_network_member(nwid, address)
        |> handle_update_backend(changeset)
      %{valid?: true, changes: %{ nwid: nwid, address: address, authorized: false }} ->
        Zerotier.One.Controller.deauthorize_network_member(nwid, address)
        |> handle_update_backend(changeset)
      %{valid?: false} ->
        {:error, changeset}
    end
  end

  defp handle_update_backend(_result = [], changeset) do
    {:error, changeset, "Could not update backend"}
  end
  defp handle_update_backend(result = %{}, _changeset) do
    {:ok, result}
  end

  defp authenticate(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      # Note how we used page_path instead of user_path
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: page_path(conn, :index))
      |> halt()
      # Stop conn to prevent downstream transformations
    end
  end

end