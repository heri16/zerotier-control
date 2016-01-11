defmodule Zerotier.One.Peer do
  @api_auth_header "X-ZT1-Auth"
  @config Application.get_env(:zerotier, Zerotier.One.Peer)
  @api_host Keyword.get(@config, :api_host)
  @api_port Keyword.get(@config, :api_port)

  def fetch(api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    peer_api_url(api_host, api_port)
    |> HTTPoison.get(api_http_headers({ api_auth_token }))
    |> handle_response
    |> decode_response
    |> convert_to_list_of_hashdicts
  end

  def api_http_headers({ api_auth_token }) when is_binary(api_auth_token) do
    [ {"Accept", "application/json"},
      { @api_auth_header, api_auth_token } ]
  end

  def peer_api_url(host, port) do
    "http://#{host}:#{port}/peer/"
  end

  def handle_response({:ok, %{status_code: 200, body: body} }), do: {:ok, body}
  def handle_response({:error, reason }), do: {:error, reason}

  def decode_response({:ok, body}), do: :jsx.decode(body)
  def decode_response({:error, reason}) do
    {_, message} = List.keyfind(reason, "message", 0)
    IO.puts "Error fetching from API: #{message}"
  end

  def convert_to_list_of_hashdicts(list) do
    list
    |> Enum.map(&Enum.into(&1, %{}))
  end
end