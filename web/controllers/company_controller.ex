defmodule Zerotier.CompanyController do
  use Zerotier.Web, :controller

  alias Zerotier.Company

  plug :authenticate
  plug :scrub_params, "company" when action in [:create, :update]

  def action(conn, _) do
    user = conn.assigns.current_user
    if not assoc_loaded?(user.tenant), do: user = user |> Repo.preload(:tenant)
    apply(__MODULE__, action_name(conn), [conn, conn.params, user])
  end

  def index(conn, _params, user) do
    companies = Repo.all(tenant_companies(user.tenant))
    render(conn, "index.html", companies: companies)
  end

  def new(conn, _params, user) do
    changeset =
      user.tenant
      |> tentant_empty_company()
      |> Company.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"company" => company_params}, user) do
    changeset = 
      user.tenant
      |> tentant_empty_company()
      |> Company.changeset(company_params)

    case Repo.insert(changeset) do
      {:ok, _company} ->
        conn
        |> put_flash(:info, "Company created successfully.")
        |> redirect(to: company_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, user) do
    company = Repo.get!(tenant_companies(user.tenant), id)
    render(conn, "show.html", company: company)
  end

  def edit(conn, %{"id" => id}, user) do
    company = Repo.get!(tenant_companies(user.tenant), id)
    changeset = Company.changeset(company)
    render(conn, "edit.html", company: company, changeset: changeset)
  end

  def update(conn, %{"id" => id, "company" => company_params}, user) do
    company = Repo.get!(tenant_companies(user.tenant), id)
    changeset = Company.changeset(company, company_params)

    case Repo.update(changeset) do
      {:ok, company} ->
        conn
        |> put_flash(:info, "Company updated successfully.")
        |> redirect(to: company_path(conn, :show, company))
      {:error, changeset} ->
        render(conn, "edit.html", company: company, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    company = Repo.get!(tenant_companies(user.tenant), id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(company)

    conn
    |> put_flash(:info, "Company deleted successfully.")
    |> redirect(to: company_path(conn, :index))
  end

  defp tenant_companies(tenant) do
    assoc(tenant, :companies)
  end

  defp tentant_empty_company(tenant, attributes \\ %{}) do
    build_assoc(tenant, :companies, attributes)
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
