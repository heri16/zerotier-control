defmodule Zerotier.CLI do
	
	@default_count 2

	@moduledoc """
	Handle command line parsing and the dispatch 
	to Windows Powershell
	"""

	def main(argv) do
		argv |> parse_args |> process
	end

	@doc """
	`argv` can be -h or --help, which returns :help.

	Otherwise it is a Zerotier IPv6 address, ztnode id,
	and (optionally) the number of connection retries.

	Return a tuple of `{ :ok, psremote_status }` or `:help` if help was given.
	"""
	def parse_args(argv) do
		parse = OptionParser.parse(argv, switches: [ help: :boolean ], aliases: [ h: :help])

		case parse do
			{ [help: true], _, _ } -> :help
			{ _, [ user, ip_address, count ], _ } -> { user, ip_address, String.to_integer(count) }
			{ _, [ user, ip_address ], _ } -> { user, ip_address, @default_count }
			_ -> :help
		end

	end

	def process(:help) do
		IO.puts """
		usage: zerotier <username> <ip_address> [ count | #{@default_count} ]
		"""
		System.halt(0)
	end

	def process({user, ip_address, _count}) do
		{:ok, pshell} = Zerotier.Powershell.start_link()
		Zerotier.Powershell.fetch_status(pshell, ip_address, user)
		|> print_status(ip_address)
		Zerotier.Powershell.stop_link(pshell)
	end

	def print_status({:ok, :online}, ip_address), do: IO.puts "Zerotier at #{ip_address} is Online."
	def print_status({:ok, :offline}, ip_address), do: IO.puts "Zerotier at #{ip_address} is Offline."
	def print_status({:ok, status}, ip_address), do: IO.puts "Zerotier status for #{ip_address} is #{status}."
	def print_status({:error, reason}, ip_address), do: IO.puts(:stderr, "Node at #{ip_address} has Error Message: " <> reason)

end