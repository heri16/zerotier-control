defmodule Zerotier.NetworkController do
  use Zerotier.Web, :controller

  alias Zerotier.Network

  plug :scrub_params, "network" when action in [:create, :update]

  def index(conn, _params) do
    networks = Repo.all(Network)
    render(conn, "index.html", networks: networks)
  end

  def new(conn, _params) do
    changeset = Network.changeset(%Network{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network" => network_params}) do
    changeset = Network.changeset(%Network{}, network_params)

    case Repo.insert(changeset) do
      {:ok, _network} ->
        conn
        |> put_flash(:info, "Network created successfully.")
        |> redirect(to: network_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    render(conn, "show.html", network: network)
  end

  def edit(conn, %{"id" => id}) do
    network = Repo.get!(Network, id)
    changeset = Network.changeset(network)
    render(conn, "edit.html", network: network, changeset: changeset)
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    network = Repo.get!(Network, id)
    changeset = Network.changeset(network, network_params)

    case Repo.update(changeset) do
      {:ok, network} ->
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

    conn
    |> put_flash(:info, "Network deleted successfully.")
    |> redirect(to: network_path(conn, :index))
  end
end
