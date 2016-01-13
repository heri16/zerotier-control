defmodule Zerotier.UserView do
  use Zerotier.Web, :view
  alias Zerotier.User

  def first_name(%{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
  
end