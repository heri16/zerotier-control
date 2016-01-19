defmodule Zerotier.NetworkController do
  use Zerotier.Web, :controller

  alias Zerotier.Network

  plug :scrub_params, "network" when action in [:create, :update]

  def index(conn, _params) do
    networks = Repo.all(Network)
    render(conn, "index.html", networks: networks)
  end

  def new(conn, _params) do
    empty_rules = for n <- 1..3, do: %Network.Rule{}
    changeset = Network.changeset(%Network{ ipLocalRoutes: [""], ipAssignmentPools: [%Network.IpAssignmentPool{}], rules: empty_rules })
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network" => network_params}) do
    changeset = Network.creation_changeset(%Network{}, network_params)

    case Repo.insert(changeset) do
      {:ok, network} ->
        backend_network =
          network
          |> update_backend_sync

        conn
        |> put_flash(:info, "Network created successfully.")
        |> redirect(to: network_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    fetched_network = fetch_backend(network)
    render(conn, "show.html", network: fetched_network)
  end

  def edit(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    fetched_network = fetch_backend(network)
    changeset = Network.changeset(fetched_network)
    render(conn, "edit.html", network: fetched_network, changeset: changeset)
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    network = Repo.get!(Network, id)
    fetched_network = fetch_backend(network)
    changeset = Network.changeset(fetched_network, network_params)

    case Repo.update(changeset) do
      {:ok, network} ->
        backend_network =
          network
          |> update_backend_sync

        conn
        |> put_flash(:info, "Network updated successfully.")
        |> redirect(to: network_path(conn, :show, network))
      {:error, changeset} ->
        render(conn, "edit.html", network: network, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(network)

    network
    |> delete_backend_sync

    conn
    |> put_flash(:info, "Network deleted successfully.")
    |> redirect(to: network_path(conn, :index))
  end

  
  def fetch_backend(network = %Network{}) do
    backend_task = Task.async(fn -> fetch_backend_sync(network) end)

    case Task.yield(backend_task, 5000) do
      {:ok, backend_network = %{} } ->
        case Network.deserialization_changeset(network, backend_network) do
          valid_changeset = %{valid?: true} ->
            valid_changeset |> Ecto.Changeset.apply_changes
          invalid_changeset ->
            IO.inspect(invalid_changeset)
            network
        end
      _ ->
        network
    end
  end

  def fetch_backend_sync(%Network{ nwid: nwid }) do
    Zerotier.One.Controller.fetch_network(nwid)
  end

  def update_backend_sync(network = %Network{ nwid: nwid }) do
    json = network |> Poison.encode!

    "http://127.0.0.1:9994/controller/network/#{nwid}"
    |> HTTPoison.post(json, [ {"Accept", "application/json"}, { "X-ZT1-Auth", "crm3h7bXRwfrg1LGra06b5zc" } ])
    |> handle_response
    |> Poison.decode!
  end

  defp handle_response({:ok, %{status_code: 200, body: body} }), do: body

  def delete_backend_sync(network = %Network{ nwid: nwid }) do
    json = network |> Poison.encode!

    "http://127.0.0.1:9994/controller/network/#{nwid}"
    |> HTTPoison.delete([ {"Accept", "application/json"}, { "X-ZT1-Auth", "crm3h7bXRwfrg1LGra06b5zc" } ])
    |> handle_response
  end

end
