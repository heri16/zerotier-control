# Zerotier

To start your Phoenix app:

  1. Install dependencies with `mix deps.get`
  2. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  3. Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: http://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix


## Windows Firewall for Powershell Node

Get-Process -Name epmd | ForEach-Object { New-NetFirewallRule -Action Allow -Name "epmd" -DisplayName "Erlang EPMD" -Group "Erlang" -Description "Inbound rule for the Erlang Port Mapper Daemon to allow EPMD traffic." -Direction Inbound -Profile Public,Private,Domain -Program $_.Path -LocalAddress ("11.0.0.0/14") -LocalPort 4369 -RemoteAddress ("11.0.0.0/14") -RemotePort Any -Protocol TCP -Enabled True }

Get-Process -Name erl | ForEach-Object { New-NetFirewallRule -Action Allow -DisplayName "Erlang EDP" -Group "Erlang" -Description "Inbound rule for the Erlang VM Node to allow EDP traffic." -Direction Inbound -Profile Public,Private,Domain -Program $_.Path -LocalAddress ("11.0.0.0/14") -LocalPort Any -RemoteAddress ("11.0.0.0/14") -RemotePort Any -Protocol TCP -Enabled True }

Get-NetFirewallRule -Group Erlang | Get-NetFirewallApplicationFilter
Get-NetFirewallRule -Group Erlang | Get-NetFirewallAddressFilter