defmodule Zerotier.One.Service do
  @api_auth_header "X-ZT1-Auth"
  @config Application.get_env(:zerotier, Zerotier.One.Service)
  @api_host Keyword.get(@config, :api_host)
  @api_port Keyword.get(@config, :api_port)
  @api_auth_token Keyword.get(@config, :api_auth_token)

  def fetch_peers(api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    service_peer_api_url(api_host, api_port)
    |> HTTPoison.get(api_http_headers(api_auth_token: api_auth_token))
    |> handle_response
    |> decode_response
    |> convert_to_list_of_maps
  end

  def api_http_headers(_options = [ api_auth_token: api_auth_token ]) when is_binary(api_auth_token) do
    [ {"Accept", "application/json"},
      { @api_auth_header, api_auth_token } ]
  end

  def service_peer_api_url(host, port) do
    "http://#{host}:#{port}/peer/"
  end

  defp handle_response({:ok, %{status_code: 200, body: body} }), do: {:ok, body}
  defp handle_response({:ok, %{status_code: 401, body: _body} }), do: {:error, "Unauthorized"}
  defp handle_response({:error, reason }), do: {:error, reason}

  defp decode_response({:ok, body}), do: :jsx.decode(body)
  defp decode_response({:error, reason}) when is_binary(reason) do
    IO.puts "Error fetching from API: #{reason}"
    []
  end
  defp decode_response({:error, reason}) when is_list(reason) do
    {_, message} = List.keyfind(reason, "message", 0)
    IO.puts "Error fetching from API: #{message}"
    []
  end

  defp convert_to_list_of_maps(list) when is_list(list) do
    list
    |> Enum.map(&Enum.into(&1, %{}))
  end
end