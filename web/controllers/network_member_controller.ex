defmodule Zerotier.NetworkMemberController do
  use Zerotier.Web, :controller

  alias Zerotier.NetworkMember

  plug :scrub_params, "network_member" when action in [:create, :update]
  plug :load_networks when action in [:index, :new, :create, :edit, :update]

  def index(conn, %{"nwid" => nwid}) when is_binary(nwid) do
    network_members = Repo.all(from m in NetworkMember, where: m.nwid == ^nwid)
    render(conn, "index.html", network_members: network_members)
  end
  def index(conn, _params) do
    network_members = Repo.all(NetworkMember)
    render(conn, "index.html", network_members: network_members)
  end

  def new(conn, _params) do
    changeset = NetworkMember.changeset(%NetworkMember{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network_member" => network_member_params}) do
    changeset = NetworkMember.changeset(%NetworkMember{}, network_member_params)

    case Repo.insert(changeset) do
      {:ok, network_member} ->
        case update_backend(network_member) do
          {:ok, _backend_network_member} ->
            conn
            |> put_flash(:info, "Network member added successfully.")
            |> redirect(to: network_member_path(conn, :index))
          {:error, backend_error} ->
            conn
            |> put_flash(:error, backend_error)
            |> redirect(to: network_member_path(conn, :index))
        end

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    network_member = Repo.get!(NetworkMember, id)
    fetched_network_member = preload_backend(network_member)
    render(conn, "show.html", network_member: fetched_network_member)
  end

  def edit(conn, %{"id" => id}) do
    network_member = Repo.get!(NetworkMember, id)
    fetched_network_member = preload_backend(network_member)
    changeset = NetworkMember.changeset(fetched_network_member)
    render(conn, "edit.html", network_member: network_member, changeset: changeset)
  end

  def update(conn, %{"id" => id, "network_member" => network_member_params}) do
    network_member = Repo.get!(NetworkMember, id)
    changeset = NetworkMember.changeset(network_member, network_member_params)

    case Repo.update(changeset) do
      {:ok, network_member} ->
        case update_backend(network_member) do
          {:ok, _backend_network_member} ->
            conn
            |> put_flash(:info, "Network member updated successfully.")
            |> redirect(to: network_member_path(conn, :show, network_member))
          {:error, backend_error} ->
            conn
            |> put_flash(:error, backend_error)
            |> redirect(to: network_member_path(conn, :show, network_member))
        end

      {:error, changeset} ->
        render(conn, "edit.html", network_member: network_member, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    network_member = Repo.get!(NetworkMember, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(network_member)

    case delete_backend(network_member) do
      {:ok, _backend_network_member} ->
        conn
        |> put_flash(:info, "Network member deleted successfully.")
        |> redirect(to: network_member_path(conn, :index))
      {:error, backend_error} ->
        conn
        |> put_flash(:error, backend_error)
        |> redirect(to: network_member_path(conn, :index))
    end
  end

  def preload_backend(network_member = %NetworkMember{}) do
    backend_task = Task.async(fn -> fetch_backend(network_member) end)

    case Task.yield(backend_task, 5000) do
      {:ok, {:ok, backend_network_member = %{}} } ->
        case NetworkMember.deserialization_changeset(network_member, backend_network_member) do
          valid_changeset = %{valid?: true} ->
            valid_changeset |> Ecto.Changeset.apply_changes
          invalid_changeset ->
            IO.inspect(invalid_changeset)
            network_member
        end
      {:ok, {:error, backend_error} } ->
        raise backend_error
      _timeout ->
        network_member
    end
  end

  def fetch_backend(%NetworkMember{ nwid: nwid, address: address }) do
    Zerotier.One.Controller.fetch_network_member(nwid, address)
  end

  def update_backend(network_member = %NetworkMember{ nwid: nwid, address: address }) do
    Zerotier.One.Controller.update_network_member(nwid, address, network_member)
  end

  def delete_backend(%NetworkMember{ nwid: nwid, address: address }) do
    Zerotier.One.Controller.delete_network_member(nwid, address)
  end

  defp load_networks(conn, _opts) do
    networks = Repo.all(from n in Zerotier.Network, select: {n.name, n.nwid})
    assign(conn, :networks, networks)
  end

end
