defmodule Zerotier.Powershell.Supervisor do
  use Supervisor

  @doc """
  Starts a `Supervisor` process linked to the current process.

  The parameter `start_options` is provided,
  its value is made as a static template in `init/1`,
  and passed as a parameter to `Zerotier.Powershell.start_link/1`
  when spawning child processes.
  """
  def start_link(start_options \\ [], options \\ []) when is_list(start_options) do
    Supervisor.start_link(__MODULE__, start_options, options)
  end

  @doc """
  Starts a powershell process as a child of this supervisor.
  
  If `start_options` has not already been provided via `start_link/1`,
  you may provide this parameter on every call of this function.
  
  Otherwise, start_options must be empty as the Simple_one_for_one Supervisor
  will always use the `start_options` passed in via `start_link/1`.
  """
  def start_powershell(supervisor, start_options \\ [])
  def start_powershell(supervisor, _start_options = []) do
    # Use static_start_options template in init/2
    Supervisor.start_child(supervisor, [])
  end
  def start_powershell(supervisor, start_options) when is_list(start_options) do
    # Use dynamic start_options
    Supervisor.start_child(supervisor, [start_options])
  end

  @doc """
  Responsible in ensuring that children processes are aware of the process registry
  """
  def init(static_start_options) when is_list(static_start_options) do
    children = case static_start_options do
      [] -> [ worker(Zerotier.Powershell, [], restart: :transient) ]
      _ -> [ worker(Zerotier.Powershell, [static_start_options], restart: :transient) ]
    end

    supervise(children, strategy: :simple_one_for_one)
  end

end
