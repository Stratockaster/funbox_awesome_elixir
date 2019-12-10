# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :funbox_awesome_elixir, FunboxAwesomeElixirWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "t+whuUxQb2rQDeIqV8a8R2ILfBlc1OfyeJYm+HurTbZpXrYfdh6Z6+u7e94l5n4X",
  render_errors: [view: FunboxAwesomeElixirWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FunboxAwesomeElixir.PubSub, adapter: Phoenix.PubSub.PG2]

config :funbox_awesome_elixir,
  github_token: "509daff7dc1b1917b3eeffc0b2c88d70f8a144d3",
  github_api_url: "https://api.github.com",
  readme_host: "https://raw.githubusercontent.com",
  readme_destination_file: "data/README.md",
  meta_file: "data/meta.json",
  ready_data_file: "data/ready_data.json",
  wait_between_requests: 100, # sec
  update_interval: 86400 # 24h

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
