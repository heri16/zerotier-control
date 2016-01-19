defmodule Zerotier.One.Controller do
  use HTTPoison.Base

  @api_auth_header "X-ZT1-Auth"
  @api_auth_token_file_paths ["/var/lib/zerotier-one/authtoken.secret", System.get_env("HOME") <> "/Library/Application Support/ZeroTier/One/authtoken.secret"]

  @config Application.get_env(:zerotier, Zerotier.One.Controller, [])
  @api_host Keyword.get(@config, :api_host, "127.0.0.1")
  @api_port Keyword.get(@config, :api_port, "9993")
  @api_auth_token Keyword.get(@config, :api_auth_token, nil)


  ## Private API and Callbacks

  def network_api_url(nwid \\ ""), do: "/network/#{nwid}"

  def network_member_api_url(nwid, naddress \\ ""), do: "/network/#{nwid}/member/#{naddress}"

  def process_url(url) do
    "http://#{@api_host}:#{@api_port}/controller/" <> String.lstrip(url, ?/)
  end

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, json} -> json
      _ -> body
    end
  end

  defp process_request_body(body = ""), do: body
  defp process_request_body(body) do
    case Poison.encode(body) do
      {:ok, json} -> json
      _ -> body
    end
  end

  defp process_request_headers(headers) when is_map(headers) do
    Enum.into(headers, [ {"Accept", "application/json"} ])
    |> append_auth_header(@api_auth_token)
  end

  defp process_request_headers(headers) do
    ([ {"Accept", "application/json"} ] ++ headers)
    |> append_auth_header(@api_auth_token)
  end

  defp append_auth_header(headers, api_auth_token) do
    if List.keyfind(headers, @api_auth_header, 0, false) do
      headers
    else
      api_auth_token = api_auth_token || read_api_auth_token()
      [ { @api_auth_header, api_auth_token } | headers]
    end
  end

  defp read_api_auth_token() do
    @api_auth_token_file_paths
    |> Enum.filter_map(&File.exists?(&1), &File.read!(&1))
    |> Enum.at(0, "")
  end

  defp handle_response({:ok, _response = %{status_code: 200, body: ""} }), do: {:ok, %{}}
  defp handle_response({:ok, _response = %{status_code: 200, body: body} }) when is_binary(body), do: {:error, body}
  defp handle_response({:ok, _response = %{status_code: 200, body: body} }), do: {:ok, body}
  defp handle_response({:ok, _response = %{status_code: 401} }), do: {:error, "Access Denied. Check authtoken."}
  defp handle_response({:ok, _response = %{status_code: status_code} }), do: {:error, status_code}
  defp handle_response(other), do: other



  ## Public API

  @doc """
  Returns {:ok, [nwid]} or {:error, any}
  """
  @spec list_networks() :: {:ok, [binary]} | {:error, any}
  def list_networks() do
    network_api_url
    |> get()
    |> handle_response()
  end

  @doc """
  Returns {:ok, [member_address]} or {:error, any}
  """
  @spec list_network_members(binary) :: {:ok, [binary]} | {:error, any}
  def list_network_members(nwid) do
    result = 
      network_member_api_url(nwid)
      |> get()
      |> handle_response()

    case result do
      {:ok, members_map = %{}} -> members_map |> Enum.map(fn {address, _} -> address end)
      other -> other
    end
  end

  @doc """
  Returns {:ok, map} or {:error, any}

  ## Map Format

  %{
    "allowPassiveBridging" => false, "authorizedMemberCount" => 289,
    "clock" => 1452853451477,
    "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    "creationTime" => 1449725457444, "enableBroadcast" => false, "gateways" => [],
    "ipAssignmentPools" => [%{"ipRangeEnd" => "11.3.255.254", "ipRangeStart" => "11.0.0.1"}],
    "ipLocalRoutes" => ["11.0.0.0/14"],
    "memberRevisionCounter" => 838, "multicastLimit" => 64,
    "name" => "sap.lmu.co.id", "nwid" => "692cb81394000001", "private" => true,
    "relays" => [], "revision" => 526,
    "rules" => %{"action" => "accept", "etherType" => 2048, "ruleNo" => 10},
      %{"action" => "accept", "etherType" => 2054, "ruleNo" => 20},
      %{"action" => "accept", "etherType" => 34525, "ruleNo" => 30}],
    "v4AssignMode" => "zt", "v6AssignMode" => "rfc4193"
  }
  """
  @spec fetch_network(binary) :: {:ok, map} | {:error, any}
  def fetch_network(nwid) do
    network_api_url(nwid)
    |> get()
    |> handle_response()

    
  end

  @doc """
  Returns {:ok, map} or {:error, any}

  ## Map Format

  %{
    "allowPassiveBridging" => false, "authorizedMemberCount" => 289,
    "clock" => 1452853451477,
    "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    "creationTime" => 1449725457444, "enableBroadcast" => false, "gateways" => [],
    "ipAssignmentPools" => [%{"ipRangeEnd" => "11.3.255.254", "ipRangeStart" => "11.0.0.1"}],
    "ipLocalRoutes" => ["11.0.0.0/14"],
    "memberRevisionCounter" => 838, "multicastLimit" => 64,
    "name" => "sap.lmu.co.id", "nwid" => "692cb81394000001", "private" => true,
    "relays" => [], "revision" => 526,
    "rules" => %{"action" => "accept", "etherType" => 2048, "ruleNo" => 10},
      %{"action" => "accept", "etherType" => 2054, "ruleNo" => 20},
      %{"action" => "accept", "etherType" => 34525, "ruleNo" => 30}],
    "v4AssignMode" => "zt", "v6AssignMode" => "rfc4193"
  }
  """
  @spec update_network(binary, any) :: {:ok, map} | {:error, any}
  def update_network(nwid, changes) do
    network_api_url(nwid)
    |> post(changes)
    |> handle_response()
  end

  @doc """
  Returns {:ok, %{}} or {:error, any}
  """
  @spec delete_network(binary) :: {:ok, map} | {:error, any}
  def delete_network(nwid) do
    network_api_url(nwid)
    |> delete()
    |> handle_response()
  end

  @doc """
  Returns {:ok, map} or {:error, any}

  ## Map Format

  %{
    "activeBridge" => false, "address" => "949ed28bc2", "authorized" => true,
    "clock" => 1452841441338,
    "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    "identity" => "949ed28bc2:0:d536019506a6fe20b920221f789f8",
    "ipAssignments" => ["11.3.2.223/14"], "memberRevision" => 837,
    "nwid" => "692cb81394000001"
  }
  """
  @spec fetch_network_member(binary, binary) :: {:ok, map} | {:error, any}
  def fetch_network_member(nwid, naddress) do
    network_member_api_url(nwid, naddress)
    |> get()
    |> handle_response()
  end

  @doc """
  Returns {:ok, map} or {:error, any}

  ## Map Format

  %{
    "activeBridge" => false, "address" => "949ed28bc2", "authorized" => true,
    "clock" => 1452841441338,
    "controllerInstanceId" => "15f22e0d8e2edaf36a5049b2494bcb0d",
    "identity" => "949ed28bc2:0:d536019506a6fe20b920221f789f8",
    "ipAssignments" => ["11.3.2.223/14"], "memberRevision" => 837,
    "nwid" => "692cb81394000001"
  }
  """
  @spec update_network_member(binary, binary, any) :: {:ok, map} | {:error, any}
  def update_network_member(nwid, naddress, changes) do
    network_member_api_url(nwid, naddress)
    |> post(changes)
    |> handle_response()
  end

  @doc """
  Returns {:ok, %{}} or {:error, any}
  """
  @spec delete_network_member(binary, binary) :: {:ok, map} | {:error, any}
  def delete_network_member(nwid, naddress) do
    network_member_api_url(nwid, naddress)
    |> delete()
    |> handle_response()
  end

end