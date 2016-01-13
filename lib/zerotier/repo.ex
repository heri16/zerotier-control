defmodule Zerotier.Repo do
  use Ecto.Repo, otp_app: :zerotier

  #def all(Zerotier.User) do
  #  [%Zerotier.User{id: "1", name: "Heri", username: "heri16", password: "elixir"},
  #   %Zerotier.User{id: "2", name: "Alfhan", username: "alfhan", password: "7langs"},
  #   %Zerotier.User{id: "3", name: "Achmad", username: "achmad", password: "easy"},
  #   %Zerotier.User{id: "4", name: "Bayu", username: "bayu", password: "phx"}]
  #end
  #def all(_module), do: []

  #def get(module, id) do
  #  Enum.find all(module), fn map -> map.id == id end
  #end

  #def get_by(module, params) do
  #  Enum.find all(module), fn map ->
  #    Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
  #  end
  #end

end
