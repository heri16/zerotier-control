defmodule Zerotier.PositionController do
  use Zerotier.Web, :controller

  alias Zerotier.Position
  alias Zerotier.Company

  plug :scrub_params, "position" when action in [:create, :update]
  plug :load_companies when action in [:index]

  def index(conn, %{"company_id" => company_id}) do
    positions = Repo.all(from p in Position, where: p.company_id == ^company_id)
    render(conn, "index.html", positions: positions)
  end
  def index(conn, _params) do
    positions = Repo.all(Position)
    render(conn, "index.html", positions: positions)
  end

  def new(conn, %{"company_id" => company_id}) do
    changeset =
      %Company{id: company_id}
      |> build_assoc(:positions)
      |> Position.changeset()
    render(conn, "new.html", changeset: changeset)
  end
  def new(conn, _params) do
    changeset = Position.changeset(%Position{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"position" => position_params}) do
    changeset = Position.changeset(%Position{}, position_params)

    case Repo.insert(changeset) do
      {:ok, position} ->
        conn
        |> put_flash(:info, "Position created successfully.")
        |> redirect(to: position_path(conn, :index, %{company_id: position.company_id} ))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    position = Repo.get!(Position, id)
    render(conn, "show.html", position: position)
  end

  def edit(conn, %{"id" => id}) do
    position = Repo.get!(Position, id)
    changeset = Position.changeset(position)
    render(conn, "edit.html", position: position, changeset: changeset)
  end

  def update(conn, %{"id" => id, "position" => position_params}) do
    position = Repo.get!(Position, id)
    changeset = Position.changeset(position, position_params)

    case Repo.update(changeset) do
      {:ok, position} ->
        conn
        |> put_flash(:info, "Position updated successfully.")
        |> redirect(to: position_path(conn, :show, position))
      {:error, changeset} ->
        render(conn, "edit.html", position: position, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    position = Repo.get!(Position, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(position)

    conn
    |> put_flash(:info, "Position deleted successfully.")
    |> redirect(to: position_path(conn, :index, %{company_id: position.company_id} ))
  end

  defp load_companies(conn = %{params: %{"company_id" => company_id}}, _opts) do
    company = Repo.one(from c in Zerotier.Company, where: c.id == ^company_id, select: {c.name, c.id})
    assign(conn, :companies, [company])
  end
  defp load_companies(conn, _opts) do
    companies = Repo.all(from c in Zerotier.Company, select: {c.name, c.id})
    assign(conn, :companies, companies)
  end
end
