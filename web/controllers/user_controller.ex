defmodule Zerotier.UserController do
  use Zerotier.Web, :controller
  alias Zerotier.User

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
        |> put_flash(:info, "#{user.name} created!")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        # Return user to new.html after the Repo module has 
        # populated the changeset with failed validations.
        render(conn, "new.html", changeset: changeset)
    end
    # Always return conn after transformation
  end

end