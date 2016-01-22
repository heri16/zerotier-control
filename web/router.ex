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

    get "/", PageController, :index
    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/networks", NetworkController
    resources "/network_members", NetworkMemberController
    get "/networks/:nwid/members", NetworkMemberController, :index

    resources "/tenants", TenantController
    resources "/companies", CompanyController
    resources "/offices", OfficeController
    resources "/departments", DepartmentController
    resources "/positions", PositionController
    resources "/profiles", ProfileController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Zerotier do
  #   pipe_through :api
  # end
end
