defmodule Zerotier.ProfileController do
  use Zerotier.Web, :controller

  alias Zerotier.Profile

  plug :authenticate
  plug :scrub_params, "profile" when action in [:create, :update]
  plug :load_offices when action in [:new, :create, :edit, :update]
  plug :load_departments when action in [:new, :create, :edit, :update]
  plug :load_positions when action in [:new, :create, :edit, :update]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    profiles = Repo.all(user_profiles(user))
    render(conn, "index.html", profiles: profiles)
  end

  def new(conn, _params, user) do
    changeset = 
      user
      |> user_empty_profile()
      |> Profile.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"profile" => profile_params}, user) do
    changeset = 
      user
      |> user_empty_profile()
      |> Profile.changeset(profile_params)

    case Repo.insert(changeset) do
      {:ok, _profile} ->
        conn
        |> put_flash(:info, "Profile created successfully.")
        |> redirect(to: profile_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, user) do
    profile = Repo.get!(user_profiles(user), id)
    render(conn, "show.html", profile: profile)
  end

  def edit(conn, %{"id" => id}, user) do
    profile = Repo.get!(user_profiles(user), id)
    changeset = Profile.changeset(profile)
    render(conn, "edit.html", profile: profile, changeset: changeset)
  end

  def update(conn, %{"id" => id, "profile" => profile_params}, user) do
    profile = Repo.get!(user_profiles(user), id)
    changeset = Profile.changeset(profile, profile_params)

    case Repo.update(changeset) do
      {:ok, profile} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: profile_path(conn, :show, profile))
      {:error, changeset} ->
        render(conn, "edit.html", profile: profile, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    profile = Repo.get!(user_profiles(user), id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(profile)

    conn
    |> put_flash(:info, "Profile deleted successfully.")
    |> redirect(to: profile_path(conn, :index))
  end

  defp user_profiles(user) do
    assoc(user, :profiles)
  end

  defp user_empty_profile(user, attributes \\ %{}) do
    build_assoc(user, :profiles, attributes)
  end

  defp load_offices(conn = %{params: %{"company_id" => company_id}}, _opts) do
    offices = Repo.all(from o in Zerotier.Office, where: o.company_id == ^company_id, select: {o.name, o.id})
    assign(conn, :offices, offices)
  end
  defp load_offices(conn, _opts) do
    offices = Repo.all(from o in Zerotier.Office, select: {o.name, o.id})
    assign(conn, :offices, offices)
  end

  defp load_departments(conn = %{params: %{"company_id" => company_id}}, _opts) do
    departments = Repo.all(from d in Zerotier.Department, where: d.company_id == ^company_id, select: {d.name, d.id})
    assign(conn, :departments, departments)
  end
  defp load_departments(conn, _opts) do
    departments = Repo.all(from d in Zerotier.Department, select: {d.name, d.id})
    assign(conn, :departments, departments)
  end

  defp load_positions(conn = %{params: %{"company_id" => company_id}}, _opts) do
    positions = Repo.all(from p in Zerotier.Position, where: p.company_id == ^company_id, select: {p.name, p.id})
    assign(conn, :positions, positions)
  end
  defp load_positions(conn, _opts) do
    positions = Repo.all(from p in Zerotier.Position, select: {p.name, p.id})
    assign(conn, :positions, positions)
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
