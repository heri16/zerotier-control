defmodule CliTest do
	use ExUnit.Case

	import Issues.CLI, only: [ parse_args: 1 ]

	test ":help returned by option parsing with -h and --help options" do
		assert parse_args(["-h", "anything"]) == :help
		assert parse_args(["--help", "anything"]) ==:help
	end

	test "two values returned if two given" do
		assert parse_args(["IT", "ip address", "99"]) == { "IT", "ip adress", 99 }
	end

	test "count is_defaulted if one value given" do
		assert parse_args(["IT", "ip address"]) == { "IT", "ip address", 2 }
	end
end