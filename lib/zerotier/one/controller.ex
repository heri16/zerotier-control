defmodule Zerotier.One.Controller do
  @api_auth_header "X-ZT1-Auth"
  @config Application.get_env(:zerotier, Zerotier.One.Controller)
  @api_host Keyword.get(@config, :api_host)
  @api_port Keyword.get(@config, :api_port)
  @api_auth_token Keyword.get(@config, :api_auth_token)

  @spec list_networks(binary, binary, pos_integer) :: [binary]
  def list_networks(api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_api_url(api_host, api_port)
    |> HTTPoison.get(api_http_headers([ api_auth_token: api_auth_token ]))
    |> handle_response
    |> decode_response
    # Returns [nwid]
  end

  @spec list_network_members(binary, binary, binary, pos_integer) :: [binary]
  def list_network_members(nwid, api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_member_api_url(api_host, api_port, nwid)
    |> HTTPoison.get(api_http_headers(api_auth_token: api_auth_token))
    |> handle_response
    |> decode_response
    |> Enum.map(fn (t) -> {address, _} = t; address end)
    # Returns [member_address]
  end

  @spec fetch_network(binary, binary, binary, pos_integer) :: map
  def fetch_network(nwid, api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_api_url(api_host, api_port, nwid)
    |> HTTPoison.get(api_http_headers([ api_auth_token: api_auth_token ]))
    |> handle_response
    |> decode_response
    |> Enum.into(%{})
    # Returns %{
    #  "allowPassiveBridging" => false, "authorizedMemberCount" => 289,
    #  "clock" => 1452853451477,
    #  "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    #  "creationTime" => 1449725457444, "enableBroadcast" => false, "gateways" => [],
    #  "ipAssignmentPools" => [[{"ipRangeStart", "11.0.0.1"},{"ipRangeEnd", "11.3.255.254"}]],
    #  "ipLocalRoutes" => ["11.0.0.0/14"],
    #  "memberRevisionCounter" => 838, "multicastLimit" => 64,
    #  "name" => "sap.lmu.co.id", "nwid" => "692cb81394000001", "private" => true,
    #  "relays" => [], "revision" => 526,
    #  "rules" => [[{"ruleNo", 10}, {"etherType", 2048}, {"action", "accept"}],
    #    [{"ruleNo", 20}, {"etherType", 2054}, {"action", "accept"}],
    #    [{"ruleNo", 30}, {"etherType", 34525}, {"action", "accept"}]],
    #  "v4AssignMode" => "zt", "v6AssignMode" => "rfc4193"
    # }
  end

  @spec fetch_network_member(binary, binary, binary, binary, pos_integer) :: map
  def fetch_network_member(nwid, naddress, api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_member_api_url(api_host, api_port, nwid, naddress)
    |> HTTPoison.get(api_http_headers([ api_auth_token: api_auth_token ]))
    |> handle_response
    |> decode_response
    |> Enum.into(%{})
    # Returns %{
    #  "activeBridge" => false, "address" => "949ed28bc2", "authorized" => true,
    #  "clock" => 1452841441338,
    #  "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    #  "identity" => "949ed28bc2:0:d536019506a6fe20b920221f789f88243842950d44e194f4e05da8e3d713bd1e031cd4549ab21094dfb643c39f27bc16e0cf52057d36968e896eb07c07a68fee",
    #  "ipAssignments" => ["11.3.2.223/14"], "memberRevision" => 837,
    #  "nwid" => "692cb81394000001"
    # }
  end

  def authorize_network_member(nwid, naddress, api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_member_api_url(api_host, api_port, nwid, naddress)
    |> HTTPoison.post(authorized_json(true), api_http_headers([ api_auth_token: api_auth_token ]))
    |> handle_response
    |> decode_response
    |> Enum.into(%{})
    # Returns %{
    #  "activeBridge" => false, "address" => "949ed28bc2", "authorized" => true,
    #  "clock" => 1452841441338,
    #  "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    #  "identity" => "949ed28bc2:0:d536019506a6fe20b920221f789f88243842950d44e194f4e05da8e3d713bd1e031cd4549ab21094dfb643c39f27bc16e0cf52057d36968e896eb07c07a68fee",
    #  "ipAssignments" => ["11.3.2.223/14"], "memberRevision" => 837,
    #  "nwid" => "692cb81394000001"
    # }
  end

  def deauthorize_network_member(nwid, naddress, api_auth_token \\ @api_auth_token, api_host \\ @api_host, api_port \\ @api_port) when is_binary(api_host) and is_integer(api_port) do
    controller_network_member_api_url(api_host, api_port, nwid, naddress)
    |> HTTPoison.post(authorized_json(false), api_http_headers([ api_auth_token: api_auth_token ]))
    |> handle_response
    |> decode_response
    |> Enum.into(%{})
  end

  def api_http_headers(_options = [ api_auth_token: api_auth_token ]) when is_binary(api_auth_token) do
    [ {"Accept", "application/json"},
      { @api_auth_header, api_auth_token } ]
  end

  def controller_network_api_url(host, port, nwid \\ "") do
    "http://#{host}:#{port}/controller/network/#{nwid}"
  end

  def controller_network_member_api_url(host, port, nwid, naddress \\ "") do
    "http://#{host}:#{port}/controller/network/#{nwid}/member/#{naddress}"
  end

  def authorized_json(authorized?) do
    :jsx.encode(%{ "authorized" => authorized? })
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

end