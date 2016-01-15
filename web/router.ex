defmodule Zerotier.Router do
  use Zerotier.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Zerotier.Auth, repo: Zerotier.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Zerotier do
    pipe_through :browser # Use the default browser stack
    
    #get "/users", UserController, :index
    #get "/users/:id", UserController, :show

    get "/", PageController, :index
    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/network_members", NetworkMemberController, only: [:index, :new, :create, :show, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Zerotier do
  #   pipe_through :api
  # end
end
