defmodule Zerotier.UserController do
  use Zerotier.Web, :controller

  alias Zerotier.User

  plug :authenticate when action in [:index, :show, :delete]
  plug :scrub_params, "user" when action in [:create, :update]
  plug :load_tenants when action in [:new, :create]

  def index(conn, _params) do
    users = Repo.all(Zerotier.User)
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get((from u in Zerotier.User, preload: [:tenant]), id)
    render(conn, "show.html", user: user)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    # Pass changeset to view to be used by form_for
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    IO.inspect(user_params)
    # Recreate changeset from POST data
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        # Transform conn with plug functions
        conn
        #|> Zerotier.Auth.login(user)
        |> put_flash(:info, "#{user.name} created!")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        # Return user to new.html after the Repo module has
        # populated the changeset with failed validations.
        render(conn, "new.html", changeset: changeset)
    end
    # Always return conn after transformation
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end

  defp load_tenants(conn = %{params: %{"tenant_id" => tenant_id}}, _opts) do
    tenant = Repo.one(from t in Zerotier.Tenant, where: t.id == ^tenant_id, select: {t.name, t.id})
    assign(conn, :tenants, [tenant])
  end
  defp load_tenants(conn, _opts) do
    tenants = Repo.all(from t in Zerotier.Tenant, select: {t.name, t.id})
    assign(conn, :tenants, tenants)
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
