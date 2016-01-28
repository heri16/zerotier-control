defmodule Zerotier.OfficeController do
  use Zerotier.Web, :controller

  alias Zerotier.Office
  alias Zerotier.Company

  plug :scrub_params, "office" when action in [:create, :update]
  plug :load_companies when action in [:index]

  def index(conn, %{"company_id" => company_id}) do
    offices = Repo.all(from o in Office, where: o.company_id == ^company_id)
    render(conn, "index.html", offices: offices)
  end
  def index(conn, _params) do
    offices = Repo.all(Office)
    render(conn, "index.html", offices: offices)
  end

  def new(conn, %{"company_id" => company_id}) do
    changeset =
      %Company{id: company_id}
      |> build_assoc(:offices)
      |> Office.changeset()
    render(conn, "new.html", changeset: changeset)
  end
  def new(conn, _params) do
    changeset = Office.changeset(%Office{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"office" => office_params}) do
    changeset = Office.changeset(%Office{}, office_params)

    case Repo.insert(changeset) do
      {:ok, office} ->
        conn
        |> put_flash(:info, "Office created successfully.")
        |> redirect(to: office_path(conn, :index, %{company_id: office.company_id} ))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    office = Repo.get!(Office, id)
    render(conn, "show.html", office: office)
  end

  def edit(conn, %{"id" => id}) do
    office = Repo.get!(Office, id)
    changeset = Office.changeset(office)
    render(conn, "edit.html", office: office, changeset: changeset)
  end

  def update(conn, %{"id" => id, "office" => office_params}) do
    office = Repo.get!(Office, id)
    changeset = Office.changeset(office, office_params)

    case Repo.update(changeset) do
      {:ok, office} ->
        conn
        |> put_flash(:info, "Office updated successfully.")
        |> redirect(to: office_path(conn, :show, office))
      {:error, changeset} ->
        render(conn, "edit.html", office: office, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    office = Repo.get!(Office, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(office)

    conn
    |> put_flash(:info, "Office deleted successfully.")
    |> redirect(to: office_path(conn, :index, %{company_id: office.company_id} ))
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
