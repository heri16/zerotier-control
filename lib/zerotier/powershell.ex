defmodule Zerotier.Powershell do
  use GenServer
  alias Porcelain.Process, as: Proc

  @moduledoc ~S"""
  A module for controlling external processes of Windows Powershell.

  ## Examples

      iex> {:ok, pshell} = Zerotier.Powershell.start_link()                    
      {:ok, #PID<0.306.0>}
      iex> Zerotier.Powershell.fetch_icmp_status(pshell, "fd69:2cb8:1394:0:199:93c0:2485:d381") 
      {:ok, :alive}

  """

  @powershell_arguments ["-NoProfile", "-NonInteractive", "-Command", "-"]
  @fetch_icmp_status_timeout 5000
  @fetch_zt_status_timeout 10000
  @sync_execute_command_timeout 10000
  @get_last_output_timeout 5000


  # Client API

  @doc """
  Starts a `Zerotier.Powershell` process linked to the current process.

  If register option is provided, starts a `Zerotier.Powershell` process,
  and associates its PID to `keyname` in a `registry_server`
  using `register_name/2` function of `registry_module`.

  ## Return values

  If the server is successfully created and initialized, the function returns
  `{:ok, pid}`, where pid is the pid of the server.
  Use `pid` with other functions defined in this module.

  If the server could not start, the process is terminated and the function returns
  `{:error, reason}`, where reason is the error reason.
  """
  @spec start_link([{atom, any}]) :: GenServer.on_start
  def start_link(args \\ :default, options)
  def start_link([process: powershell_proc = %Proc{}], options) when is_list(options) do
    GenServer.start_link(__MODULE__, {:process, powershell_proc}, options)
  end
  def start_link(args, options) when is_list(options) do
    GenServer.start_link(__MODULE__, args, options)
  end

  @spec register_via(GenServer.on_start, {:via, module, term}) :: GenServer.on_start
  def register_via(result = {:ok, powershell_pid}, _register_info = {:via, registry_module, {registry_server, keyname}}) do
    # Dynamic call to register_name/2 function in registry_module
    case registry_module.register_name({registry_server, keyname}, powershell_pid) do
      :yes ->
        result
      :no ->
        GenServer.stop(powershell_pid, :shutdown)
        {:error, "Could not register the #{__MODULE__} process"}
    end
  end
  def register_via(other_result, _register_info) do
    other_result
  end

  @doc """
  Unlinks a `GenServer` process linked to the current process, and stops it normally.

  ## Return Values

  If the server has terminated, the function returns
  `:ok`.
  """
  @spec stop_link(pid):: :ok
  def stop_link(pid) when is_pid(pid) do
    Process.unlink(pid)
    GenServer.stop(pid, :normal)
  end

  @doc """
  Fetch a node's general status using ICMP and WinRM.

  ## Return values

  If there are no errors, the function returns
  `{:ok, status}`, where status is one of the the atoms below:
  - :dead - Did not respond to icmp echo requests
  - :alive - Responded to icmp echo requests, but could not fetch zerotier status
  - :online - Zerotier node reported its status as online
  - :offline - Zerotier node reported its status as offline

  If there are errors, the function returns
  `{:error, reason}`, where reason is the unexpected output
  or error reason form the external powershell process.
  """
  @spec fetch_status(pid | Proc.t, String.t, String.t) :: {:ok, atom} | {:error, any}
  def fetch_status(pid, ip_address, username) when is_pid(pid) do
    icmp_status = fetch_icmp_status(pid, ip_address)
    is_icmp_alive? = case icmp_status do
        {:ok, :alive} ->
          IO.puts "Node at #{ip_address} is Alive."
          true
        {:ok, :dead} ->
          IO.puts "Node at #{ip_address} is Dead."
          false
        {:error, _reason} ->
          false
    end
    if is_icmp_alive? do
      zt_status = fetch_zt_status(pid, ip_address, username)
      zt_status
    else
      icmp_status
    end
  end
  def fetch_status(proc = %Proc{}, ip_address, username) do
    icmp_status = fetch_icmp_status(proc, ip_address)
    is_icmp_alive? = case icmp_status do
        {:ok, :alive} ->
          IO.puts "Node at #{ip_address} is Alive."
          true
        {:ok, :dead} ->
          IO.puts "Node at #{ip_address} is Dead."
          false
        {:error, _reason} ->
          false
    end
    if is_icmp_alive? do
      zt_status = fetch_zt_status(proc, ip_address, username)
      zt_status
    else
      icmp_status
    end
  end

  @doc """
  Fetch a node's status using ICMP.

  ## Return values

  Refer to `fetch_status/3`
  """
  @spec fetch_icmp_status(pid | Proc.t, String.t) :: {:ok, atom} | {:error, any}
  def fetch_icmp_status(pid, ip_address) when is_pid(pid) do
    input = "ping -n 2 #{ip_address}"
    output = GenServer.call(pid, {:in, input}, @fetch_icmp_status_timeout)
    cond do
      (Regex.match?(~r/average/iu, output)) -> {:ok, :alive}
      (Regex.match?(~r/100% loss/iu, output)) -> {:ok, :dead}
      true -> {:error, output}
    end
  end
  def fetch_icmp_status(proc = %Proc{}, ip_address) do
    input = "ping -n 2 #{ip_address}"
    output = sync_send_input(proc, input)
    cond do
      (Regex.match?(~r/average/iu, output)) -> {:ok, :alive}
      (Regex.match?(~r/100% loss/iu, output)) -> {:ok, :dead}
      true -> {:error, output}
    end
  end

  @doc """
  Fetch a node's status using Powershell Remoting (WinRM).

  ## Return values

  Refer to `fetch_status/3`
  """
  @spec fetch_zt_status(pid | Proc.t, String.t, String.t) :: {:ok, atom} | {:error, any}
  def fetch_zt_status(pid, ip_address, username) when is_pid(pid) do
    input = """
      Invoke-Command -ComputerName #{ip_address} -Credential #{username} -ScriptBlock { C:\\ProgramData\\Zerotier\\One\\zerotier-one_x*.exe -q info }
      """
    output = GenServer.call(pid, {:in, input}, @fetch_zt_status_timeout)
    cond do
      (Regex.match?(~r/ONLINE/iu, output)) -> {:ok, :online}
      (Regex.match?(~r/OFFLINE/iu, output)) -> {:ok, :offline}
      true -> {:error, output}
    end
  end
  def fetch_zt_status(proc = %Proc{}, ip_address, username) do
    input = """
      Invoke-Command -ComputerName #{ip_address} -Credential #{username} -ScriptBlock { C:\\ProgramData\\Zerotier\\One\\zerotier-one_x*.exe -q info }
      """
    output = sync_send_input(proc, input)
    cond do
      (Regex.match?(~r/ONLINE/iu, output)) -> {:ok, :online}
      (Regex.match?(~r/OFFLINE/iu, output)) -> {:ok, :offline}
      true -> {:error, output}
    end
  end

  @doc """
  Executes a user-defined Powershell Command or Script-block,
  and waits for output to complete.

  ## Return values

  The function waits for output to complete, and returns
  `output`, where output is a string (binary) from the stdio or stderr stream.
  """
  @spec sync_execute_command(pid, binary, timeout) :: binary
  def sync_execute_command(pid, input, timeout \\ @sync_execute_command_timeout) when is_pid(pid) and is_binary(input) do
    GenServer.call(pid, {:in, "& {" <> input <> "}" }, timeout)
  end

  @doc """
  Executes a user-defined Powershell Command or Script-block,
  without waiting for output.
  Use `get_last_output/2` to retrieve the output.

  ## Return values

  The function returns
  `:ok` or `input`, where input is the 2nd parameter.
  """
  @spec execute_command(pid, binary) :: :ok
  def execute_command(pid, input) when is_pid(pid) and is_binary(input) do
    GenServer.cast(pid, {:in, "& {" <> input <> "}" })
  end
  @spec execute_command(Proc.t, binary) :: binary
  def execute_command(proc = %Proc{}, input) when is_binary(input) do
    send_input(proc, "& {" <> input <> "}")
  end

  @doc """
  Retreive the output from stdio and stderr stream.
  Waits for the output to complete if is has not.

  ## Return values

  The function waits for output to complete, and returns
  `output`, where output is a string (binary) from the stdio or stderr stream.
  """
  @spec get_last_output(pid | Proc.t, timeout) :: binary
  def get_last_output(_, timeout \\ @get_last_output_timeout)
  def get_last_output(pid, timeout) when is_pid(pid) do
    GenServer.call(pid, :out, timeout)
  end
  def get_last_output(_proc = %Proc{pid: pid}, timeout) do
    receive_output_till_eof(pid, timeout)
  end

  @doc """
  Starts a `Porcelain.Process`, and returns its struct.
  Normally, `start_link/1` should be used.
  Only use this when `GenServer` is not preferred.

  ## Return values

  If the external process is successfully created and initialized, the function returns
  `{:ok, proc}`, where proc is the `Porcelain.Process` created.
  Use `proc` with other functions defined in this module.

  If the external process could not start, the function returns
  `{:error, exception}`, where reason is the error exception.
  """
  @spec start_proc() :: {:ok, Proc.t} | {:error, any}
  def start_proc() do
    try do
      proc = Porcelain.spawn("powershell", @powershell_arguments, in: :receive, out: {:send, self()})
      {:ok, proc}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Stops a `Procelain.Process`.
  Only use this when `GenServer` is not preferred.

  ## Return Values
  
  If the process has terminated, the function returns
  `{:ok, exit_code}`, where exit_code is an integer
  that is returned when the external process exited.
  """
  @spec stop_proc(Proc.t) :: {:ok, integer} | :timeout
  def stop_proc(proc = %Proc{pid: pid}) do
    Proc.send_input(proc, "\nExit 0\n")
    receive do
      {^pid, :result, %Porcelain.Result{status: status}} -> {:ok, status}
    end
  end


  # Server Callbacks

  @doc """
  Responsible for spawning the external process
  """
  def init({:process, proc = %Proc{}}) do
    {:ok, %{accumulator: [], clients: [], proc: proc} }
  end
  def init(_args) do
    try do
      proc = %Proc{pid: pid} = Porcelain.spawn("powershell", @powershell_arguments, in: :receive, out: {:send, self()})
      Process.link(pid)
      {:ok, %{accumulator: [], clients: [], proc: proc} }
    rescue
      e -> {:stop, e}
    end
  end

  @doc """
  Responsible for receiving and accumulating output from the external process, 
  and handling timeout and exit conditions.
  """
  def handle_info({pid, :data, :out, <<0>>}, state = %{accumulator: accumulator, clients: _clients = [], proc: _proc = %Proc{pid: pid}}) do
    {:noreply, %{state | accumulator: [<<0>> | accumulator] } }
  end
  def handle_info({pid, :data, :out, <<0>>}, state = %{accumulator: accumulator, clients: _clients = [client | other_clients], proc: _proc = %Proc{pid: pid}}) do
    output = accumulator |> Enum.reverse |> Enum.join
    case GenServer.reply(client, output) do
      :ok -> {:noreply, %{state | accumulator: [], clients: other_clients} }
      _ -> {:noreply, %{state | accumulator: [<<0>> | accumulator], clients: other_clients} }
    end
  end
  def handle_info({pid, :data, :out, "\r\n"}, state = %{accumulator: [], proc: _proc = %Proc{pid: pid}}) do
    # Discards first linebreak
    {:noreply, state}
  end
  def handle_info({pid, :data, :out, data}, state = %{accumulator: accumulator, proc: _proc = %Proc{pid: pid}}) when is_binary(data) do
    # IO.inspect data
    {:noreply,  %{state | accumulator: [data | accumulator] }, 30000}
  end
  def handle_info({pid, :result, %Porcelain.Result{status: status}}, state = %{proc: _proc = %Proc{pid: pid}}) do
    {:stop, "Powershell Process exited unexpectedly", Map.put(state, :exit_code, status) }
  end
  def handle_info(:timeout, state = %{clients: _clients = [client | other_clients] }) do
    GenServer.reply(client, "GenServer Timeout")
    {:noreply, %{state | clients: other_clients} }
  end

  @doc """
  Responsible for sending input to the external process, in an asynchronous manner.
  Use GenServer.call(:out) to get the buferred output.
  """
  def handle_cast({:in, input}, state = %{proc: proc = %Proc{}}) do
    # TODO: Fix indeterministic deadlock when cast/2 is called multiple times
    Proc.send_input(proc, input <> ~s<\n[Console]::Out.Write("`0")\n> )
    {:noreply, state}
  end

  @doc """
  Responsible for sending input to the external process, or retrieving buferred output
  in a synchronous manner.

  When multiple clients call simultaneously, the `clients` queue length will grow. 
  Performance tradeoffs have been made for lower latency of reply
  over higher cost of appending to the queue.
  """
  def handle_call(:out, from, state = %{accumulator: _accumulator = [], clients: clients}) do
    # Output not ready
    {:noreply, %{state | clients: clients ++ [from]} }
  end
  def handle_call(:out, from, state = %{accumulator: _accumulator = [acc_head|acc_tail], clients: clients}) do
    case acc_head do
      <<0>> ->
        # Output ready
        output = acc_tail |> Enum.reverse |> Enum.join
        {:reply, output, %{state | accumulator: []} }
      _ ->
        # Output not ready
        {:noreply, %{state | clients: clients ++ [from]} }
    end
  end
  def handle_call({:in, input}, from, state = %{clients: clients, proc: proc = %Proc{}}) do
    Proc.send_input(proc, input <> ~s<\n[Console]::Out.Write("`0")\n> )
    # Output not ready
    {:noreply, %{state | clients: clients ++ [from]} }
  end

  @doc """
  Responsible for sending cleaning up the external process on GenServer termination. 
  """
  def terminate(reason, state = %{proc: proc = %Proc{pid: pid}}) do
    if Proc.alive?(proc) do
      Proc.send_input(proc, "\nExit 0\n")
      receive do
        {^pid, :result, %Porcelain.Result{status: status}} -> super(reason, Map.put(state, :exit_code, status))
      end
    else
      super(reason, state)
    end
  end


  defp sync_send_input(proc = %Proc{pid: pid}, input) do
    send_input(proc, input)
    receive_output_till_eof(pid)
  end

  defp send_input(proc = %Proc{}, input) do
    Proc.send_input(proc, input <> ~s<\n[Console]::Out.Write("`0")\n> )
  end

  defp receive_output_till_eof(pid, timeout \\ 5000, accumulator \\ "") do
    receive do
      {^pid, :data, :out, <<0>>} -> accumulator
      {^pid, :data, :out, data} when is_binary(data) -> receive_output_till_eof(pid, timeout, accumulator <> data)
    after
      timeout -> accumulator
    end
  end

end
