defmodule Zerotier.TenantController do
  use Zerotier.Web, :controller

  alias Zerotier.Tenant

  plug :authenticate
  plug :scrub_params, "tenant" when action in [:create, :update]

  def index(conn, _params) do
    tenants = Repo.all(Tenant)
    render(conn, "index.html", tenants: tenants)
  end

  def new(conn, _params) do
    changeset = Tenant.changeset(%Tenant{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"tenant" => tenant_params}) do
    changeset = Tenant.creation_changeset(%Tenant{}, tenant_params)

    case Repo.insert(changeset) do
      {:ok, _tenant} ->
        conn
        |> put_flash(:info, "Tenant created successfully.")
        |> redirect(to: tenant_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    tenant = Repo.get!(Tenant, id)
    render(conn, "show.html", tenant: tenant)
  end

  def edit(conn, %{"id" => id}) do
    tenant = Repo.get!(Tenant, id)
    changeset = Tenant.changeset(tenant)
    render(conn, "edit.html", tenant: tenant, changeset: changeset)
  end

  def update(conn, %{"id" => id, "tenant" => tenant_params}) do
    tenant = Repo.get!(Tenant, id)
    changeset = Tenant.changeset(tenant, tenant_params)

    case Repo.update(changeset) do
      {:ok, tenant} ->
        conn
        |> put_flash(:info, "Tenant updated successfully.")
        |> redirect(to: tenant_path(conn, :show, tenant))
      {:error, changeset} ->
        render(conn, "edit.html", tenant: tenant, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tenant = Repo.get!(Tenant, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(tenant)

    conn
    |> put_flash(:info, "Tenant deleted successfully.")
    |> redirect(to: tenant_path(conn, :index))
  end

  defp authenticate(conn, _opts) do
    case conn.assigns.current_user do
      %Zerotier.User{id: 1} ->
        conn
      %Zerotier.User{} -> 
        # Note how we used page_path instead of user_path
        conn
        |> put_flash(:error, "You do not have access rights for that page")
        |> redirect(to: page_path(conn, :index))
        |> halt()
        # Stop conn to prevent downstream transformations
      _others -> 
        # Note how we used page_path instead of user_path
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: page_path(conn, :index))
        |> halt()
        # Stop conn to prevent downstream transformations
    end
  end
end
