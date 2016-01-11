defmodule Zerotier.PageController do
  use Zerotier.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
