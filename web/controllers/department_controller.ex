defmodule Zerotier.DepartmentController do
  use Zerotier.Web, :controller

  alias Zerotier.Department
  alias Zerotier.Company

  plug :scrub_params, "department" when action in [:create, :update]
  plug :load_companies when action in [:index]

  def index(conn, %{"company_id" => company_id}) do
    departments = Repo.all(from d in Department, where: d.company_id == ^company_id)
    render(conn, "index.html", departments: departments)
  end
  def index(conn, _params) do
    departments = Repo.all(Department)
    render(conn, "index.html", departments: departments)
  end

  def new(conn, %{"company_id" => company_id}) do
    changeset =
      %Company{id: company_id}
      |> build_assoc(:departments)
      |> Department.changeset()
    render(conn, "new.html", changeset: changeset)
  end
  def new(conn, _params) do
    changeset = Department.changeset(%Department{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"department" => department_params}) do
    changeset = Department.changeset(%Department{}, department_params)

    case Repo.insert(changeset) do
      {:ok, department} ->
        conn
        |> put_flash(:info, "Department created successfully.")
        |> redirect(to: department_path(conn, :index, %{company_id: department.company_id} ))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    department = Repo.get!(Department, id)
    render(conn, "show.html", department: department)
  end

  def edit(conn, %{"id" => id}) do
    department = Repo.get!(Department, id)
    changeset = Department.changeset(department)
    render(conn, "edit.html", department: department, changeset: changeset)
  end

  def update(conn, %{"id" => id, "department" => department_params}) do
    department = Repo.get!(Department, id)
    changeset = Department.changeset(department, department_params)

    case Repo.update(changeset) do
      {:ok, department} ->
        conn
        |> put_flash(:info, "Department updated successfully.")
        |> redirect(to: department_path(conn, :show, department))
      {:error, changeset} ->
        render(conn, "edit.html", department: department, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    department = Repo.get!(Department, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(department)

    conn
    |> put_flash(:info, "Department deleted successfully.")
    |> redirect(to: department_path(conn, :index, %{company_id: department.company_id} ))
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
