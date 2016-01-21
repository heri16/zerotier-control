defmodule Zerotier do
  use Application

  @moduledoc """
  """

  @windows_node :"windows@11.1.1.1"

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    start_more_children? = true

    children = case Node.self() do
      @windows_node ->
        start_more_children? = false
        []
      _ ->
        [
          # Start the endpoint when the application starts
          supervisor(Zerotier.Endpoint, []),
          # Start the Ecto repository
          supervisor(Zerotier.Repo, []),
          # Here you could define other workers and supervisors as children
          # worker(Zerotier.Worker, [arg1, arg2, arg3]),
        ]
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zerotier.Supervisor]

    children
    |> Supervisor.start_link(opts)
    |> handle_start_supervisor(start_more_children?)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Zerotier.Endpoint.config_change(changed, removed)
    :ok
  end


  @spec handle_start_supervisor(Supervisor.on_start, boolean) :: Supervisor.on_start
  defp handle_start_supervisor(result = {:ok, supervisor_pid }, start_more?) do
    if start_more?, do: supervisor_pid |> start_other_children
    result
  end
  defp handle_start_supervisor(other_result, _start_more?) do
    other_result
  end

  @doc """
  Adds a more complicated supervision tree to the root supervisor
  """
  @spec start_other_children(Supervisor.t) :: Supervisor.on_start_child
  def start_other_children(supervisor_server) do
    import Supervisor.Spec, warn: false

    # Start Registry process on local node
    {:ok, registry_pid} = Supervisor.start_child(supervisor_server,
      worker(Zerotier.Registry, [ [name: :"Zerotier.ProcessRegistry"] ]))

    # Start Powershell supervisor process on which node?
    target_supervisor_server = case Node.ping(@windows_node) do
      :pong ->
        IO.puts "VM Node #{@windows_node} is alive"
        { Zerotier.Supervisor, @windows_node}
      :pang ->
        supervisor_server
    end

    target_supervisor_server
    |> start_powershell_supervisor
    |> handle_start_powershell_supervisor(registry_pid, "default-powershell")
    |> IO.inspect
  end

  @spec start_powershell_supervisor(Supervisor.t) :: Supervisor.on_start_child
  defp start_powershell_supervisor(supervisor_server) do
    import Supervisor.Spec, warn: false

    Supervisor.start_child(supervisor_server, supervisor(Zerotier.Powershell.Supervisor, []))
  end

  @spec handle_start_powershell_supervisor(Supervisor.on_start_child, GenServer.t, term) :: Supervisor.on_start_child
  defp handle_start_powershell_supervisor({:ok, powershell_supervisor}, registry_pid, keyname) do
    powershell_supervisor
    |> Zerotier.Powershell.Supervisor.start_powershell([ name: {:via, Zerotier.Registry, {registry_pid, keyname}} ])
  end
  defp handle_start_powershell_supervisor({:error, {:already_started, powershell_supervisor}}, registry_pid, keyname) do
    handle_start_powershell_supervisor({:ok, powershell_supervisor}, registry_pid, keyname)
  end
  defp handle_start_powershell_supervisor(other_result, _registry_pid, _keyname) do
    IO.inspect(other_result)
  end

end
