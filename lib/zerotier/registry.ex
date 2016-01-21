defmodule Zerotier.Registry do
  use GenServer

  @moduledoc ~S"""
  Instead of abusing the Process Name Registry facility in Erlang VM,
  we have our own registry process that associates a name to the PID. 
  """

  # Name of process to default to when using {:via} API:
  # Process.send({:via, module, {:ProcessRegistry, keyname}}, ...)
  @via_default_registry :"Zerotier.ProcessRegistry"

  ## Client API

  @doc """
  Starts the registry with the given `name`.
  """
  def start_link(_options = [name: process_name, table_name: table_name]) when is_atom(process_name) do
    GenServer.start_link(__MODULE__, table_name, name: process_name)
  end
  def start_link(_options = [name: process_name]) when is_atom(process_name) do
    start_link([name: process_name, table_name: process_name])
  end
  def start_link(_options = []) do
    start_link([name: @via_default_registry, table_name: @via_default_registry])
  end

  @doc """
  Returns the `table_name` of the ets lookup table that stores cached PIDs.
  """
  def fetch_table_name(registry_server \\ @via_default_registry) do
    GenServer.call(registry_server, :table_name)
  end

  @doc """
  Looks up the cached PID by `keyname` stored in `registry_server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  @spec fetch(GenServer.t, Map.key) :: {:ok, pid} | :error
  def fetch(registry_server \\ @via_default_registry, keyname)
  def fetch(registry_server, keyname) when is_atom(registry_server) do
    # Client reads directly from shared ETS table owned by the registry process
    table_name = registry_server
    case :ets.lookup(table_name, keyname) do
      [{^keyname, process_pid, _ref}] -> {:ok, process_pid}
      [] -> :error
    end
  end
  def fetch(registry_server, keyname) when is_pid(registry_server) or is_port(registry_server) do
    # Client have to get table_name before reading directly from shared ETS table
    if Kernel.node(registry_server) == Kernel.node() do
      # Local ets:
      registry_server |> fetch_table_name |> fetch(keyname)
    else
      # Remote ets:
      GenServer.call(registry_server, {:lookup, keyname})
    end
  end

  @doc """
  Adds a PID associated to the given `keyname` in `registry_server`.
  """
  @spec put_new(GenServer.t, Map.key, pid) :: GenServer.t
  def put_new(registry_server \\ @via_default_registry, keyname, process_pid)
  def put_new(registry_server, keyname, process_pid) do
    GenServer.call(registry_server, {:insert_new, keyname, process_pid})
    registry_server
  end

  @doc """
  Removes a PID associated to the given `keyname` in `registry_server`.
  """
  @spec delete(GenServer.t, Map.key) :: GenServer.t
  def delete(registry_server \\ @via_default_registry, keyname)
  def delete(registry_server, keyname) do
    GenServer.call(registry_server, {:delete, keyname})
    registry_server
  end

  @doc """
  Unlinks a `GenServer` process linked to the current process, and stops it normally.
  """
  def stop_link(registry_server) do
    :true = Process.unlink(registry_server)
    stop(registry_server)
  end

  @doc """
  Stops a `Zerotier.Registry` process normally.
  """
  def stop(registry_server) do
    GenServer.stop(registry_server, :normal)
  end


  ## GenServer API for {:via, module, term}

  @spec register_name({GenServer.server, term} | term, pid) :: :yes | :no
  def register_name({registry_server, keyname}, process_pid) do
    case GenServer.call(registry_server, {:insert_new, keyname, process_pid}) do
      :ok -> :yes
      {:error, _} -> :no
      _ -> :no
    end
  end
  def register_name(keyname, process_pid) do
    register_name({@via_default_registry, keyname}, process_pid)
  end

  @spec unregister_name({GenServer.server, term} | term) :: term
  def unregister_name({registry_server, keyname}) do
    case GenServer.call(registry_server, {:delete, keyname}) do
      :ok -> keyname
      _ -> nil
    end
  end
  def unregister_name(keyname) do
    unregister_name({@via_default_registry, keyname})
  end

  @spec whereis_name({GenServer.server, term} | term) :: pid | :undefined
  def whereis_name({registry_server, keyname}) do
    case fetch(registry_server, keyname) do
      {:ok, process_pid} -> process_pid
      :error -> :undefined
    end
  end
  def whereis_name(keyname) do
    whereis_name({@via_default_registry, keyname})
  end

  @spec send({GenServer.server, term} | term, term) :: pid | :undefined
  def send({registry_server, keyname}, message) do
    case fetch(registry_server, keyname) do
      {:ok, process_pid} when is_pid(process_pid) ->
        Process.send(process_pid, message)
      {:ok, process_atom} when is_atom(process_atom) ->
        Process.send(process_atom, message)
      {:ok, process_atom_node = {process_atom, _node}} when is_atom(process_atom) ->
        Process.send(process_atom_node, message)
    end

    whereis_name({registry_server, keyname})
  end
  def send(keyname, message) do
    __MODULE__.send({@via_default_registry, keyname}, message)
  end


  ## Server callbacks

  def init(table_name) do
    pid_lookup_table = :ets.new(table_name, [:named_table, read_concurrency: true])
    refs  = %{}
    {:ok, {pid_lookup_table, refs}}
  end

  def handle_call(:table_name, _from, state = {pid_lookup_table, _refs}) do
    {:reply, pid_lookup_table, state}
  end

  def handle_call({:insert_new, keyname, process_pid}, _from, state = {pid_lookup_table, refs}) do
    ref = Process.monitor(process_pid)

    case :ets.insert_new(pid_lookup_table, {keyname, process_pid, ref}) do
      :false ->
        Process.demonitor(ref)
        {:reply, {:error, "Key already exists"}, state}
      :true ->
        updated_refs = Map.put_new(refs, ref, keyname)
        {:reply, :ok, {pid_lookup_table, updated_refs}}
    end
  end
  def handle_call({:lookup, keyname}, _from, state = {pid_lookup_table, _refs}) do
    case :ets.lookup(pid_lookup_table, keyname) do
      [] -> {:reply, :error, state}
      [{^keyname, process_pid, _ref}] -> {:reply, {:ok, process_pid}, state}
    end
  end
  def handle_call({:delete, keyname}, _from, state = {pid_lookup_table, refs}) do
    case :ets.lookup(pid_lookup_table, keyname) do
      [] -> {:reply, :error, state}
      [{^keyname, _process_pid, ref}] ->
        Process.demonitor(ref)
        other_refs = Map.delete(refs, ref)
        case :ets.delete(pid_lookup_table, keyname) do
          :true -> {:reply, :ok, {pid_lookup_table, other_refs}}
          other -> {:reply, other, {pid_lookup_table, other_refs}}
        end
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state = {pid_lookup_table, refs}) do
    # When process is terminating, signal is trapped and the process is deleted from the ETS table
    case Map.pop(refs, ref) do
      {nil, _refs} ->
        {:noreply, state}
      {keyname, other_refs} ->
        :true = :ets.delete(pid_lookup_table, keyname)
        {:noreply, {pid_lookup_table, other_refs}}
    end
  end

end
