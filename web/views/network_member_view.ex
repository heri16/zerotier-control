defmodule Zerotier.NetworkMemberView do
  use Zerotier.Web, :view

  def keys(member) do
    member
    |> Map.keys
  end
end