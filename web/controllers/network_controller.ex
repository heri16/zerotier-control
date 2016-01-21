defmodule Zerotier.NetworkController do
  use Zerotier.Web, :controller

  alias Zerotier.Network

  plug :scrub_params, "network" when action in [:create, :update]

  def index(conn, _params) do
    networks = Repo.all(Network)
    render(conn, "index.html", networks: networks)
  end

  def new(conn, _params) do
    empty_rules = for n <- 1..3, do: %Network.Rule{ ruleNo: n*10 }
    new_network = %Network{ ipLocalRoutes: [""], ipAssignmentPools: [%Network.IpAssignmentPool{}], rules: empty_rules }
    changeset = Network.changeset(new_network)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network" => network_params}) do
    changeset = Network.changeset(%Network{}, network_params)

    case Repo.insert(changeset) do
      {:ok, network} ->
        case update_backend(network) do
          {:ok, _backend_network} ->
            conn
            |> put_flash(:info, "Network created successfully.")
            |> redirect(to: network_path(conn, :index))
          {:error, backend_error} ->
            conn
            |> put_flash(:error, backend_error)
            |> redirect(to: network_path(conn, :index))
        end

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    fetched_network = preload_backend(network)
    render(conn, "show.html", network: fetched_network)
  end

  def edit(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    fetched_network = preload_backend(network)
    changeset = Network.changeset(fetched_network)
    render(conn, "edit.html", network: fetched_network, changeset: changeset)
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    network = Repo.get!(Network, id)
    fetched_network = preload_backend(network)
    changeset = Network.changeset(fetched_network, network_params)

    case Repo.update(changeset) do
      {:ok, network} ->
        case update_backend(network) do
          {:ok, _backend_network} ->
            conn
            |> put_flash(:info, "Network updated successfully.")
            |> redirect(to: network_path(conn, :show, network))
          {:error, backend_error} ->
            conn
            |> put_flash(:error, backend_error)
            |> redirect(to: network_path(conn, :show, network))
        end

      {:error, changeset} ->
        render(conn, "edit.html", network: network, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(network)

    case delete_backend(network) do
      {:ok, _backend_network} ->
        conn
        |> put_flash(:info, "Network deleted successfully.")
        |> redirect(to: network_path(conn, :index))
      {:error, backend_error} ->
        conn
        |> put_flash(:error, backend_error)
        |> redirect(to: network_path(conn, :index))
    end
  end


  def preload_backend(network = %Network{}) do
    backend_task = Task.async(fn -> fetch_backend(network) end)

    case Task.yield(backend_task, 5000) do
      {:ok, {:ok, backend_network = %{}} } ->
        case Network.deserialization_changeset(network, backend_network) do
          valid_changeset = %{valid?: true} ->
            valid_changeset |> Ecto.Changeset.apply_changes
          invalid_changeset ->
            IO.inspect(invalid_changeset)
            network
        end
      {:ok, {:error, backend_error} } ->
        raise backend_error
      _timeout ->
        network
    end
  end

  def fetch_backend(%Network{ nwid: nwid }) do
    Zerotier.One.Controller.fetch_network(nwid)
  end

  def update_backend(network = %Network{ nwid: nwid }) do
    Zerotier.One.Controller.update_network(nwid, network)
  end

  def delete_backend(%Network{ nwid: nwid }) do
    Zerotier.One.Controller.delete_network(nwid)
  end

end
