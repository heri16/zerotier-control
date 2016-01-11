# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :zerotier, Zerotier.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "KPGxeGSJZ2mI0BziloQXJeLRebFDiEAXPLQFFOt30DfgnXwadBq9jz+d/LA4jHKv",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Zerotier.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

# Configure porcelain
config :porcelain,
  goon_warn_if_missing: false

# Configure Zerotier One API
config :zerotier, Zerotier.One.Peer,
  api_host: "127.0.0.1" ,
  api_port: 9993
config :zerotier, Zerotier.One.Controller,
  api_host: "127.0.0.1" ,
  api_port: 9993
