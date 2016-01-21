defmodule Zerotier.UserController do
  use Zerotier.Web, :controller
  alias Zerotier.User

  plug :authenticate when action in [:index, :show]

  def index(conn, _params) do
    users = Repo.all(Zerotier.User)
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(Zerotier.User, id)
    render(conn, "show.html", user: user)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    # Pass changeset to view to be used by form_for
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # Recreate changeset from POST data
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        # Transform conn with plug functions
        conn
        |> Zerotier.Auth.login(user)
        |> put_flash(:info, "#{user.name} created!")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        # Return user to new.html after the Repo module has
        # populated the changeset with failed validations.
        render(conn, "new.html", changeset: changeset)
    end
    # Always return conn after transformation
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
