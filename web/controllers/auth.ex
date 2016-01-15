defmodule Zerotier.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2]

  @moduledoc """
  Plug module to help controllers do authentication.

  Added to browser pipeline in web/router.ex file.
  """


  @doc """
  This function is called during compile time to
  define 2nd parameter of `call/2`.
  """
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  @doc """
  This function is called in browser pipeline for every request
  received during runtime.
  """
  def call(conn, repo) do
    # Check session for user_id
    user_id = get_session(conn, :user_id)
    # Lookup user
    user = user_id && repo.get(Zerotier.User, user_id)
    assign(conn, :current_user, user)
  end

  @doc """
  Helper function to logout the authenticated user session.
  """
  def logout(conn) do
    # Drop the whole session at the end of the request
    #configure_session(conn, drop: true)
    # Delete only user_id from session
    #delete_session(conn, :user_id)
    # Delete all keys from session (allows put_flash to work)
    clear_session(conn)
  end

  @doc """
  Helper function to create a session for an authenticated user.
  Used in `login_by_username_and_pass/4`.
  """
  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
    # Send the session cookie back to the client with a different identifier,
    # in case an attacker knew, by any chance, the previous one.
  end

  @doc """
  Helper function to authenticate the user.
  Used in `Zerotier.SessionController`.
  """
  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Zerotier.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        {:error, :not_found, conn}
    end
  end
end