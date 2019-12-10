use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :funbox_awesome_elixir, FunboxAwesomeElixirWeb.Endpoint,
  http: [port: 4002],
  server: false

config :funbox_awesome_elixir,
  github_api_url: "http://localhost:1366",
  readme_host: "http://localhost:1367",
  readme_destination_file: "test/funbox_awesome_elixir/data/README.md",
  meta_file: "test/funbox_awesome_elixir/data/meta.json",
  ready_data_file: "test/funbox_awesome_elixir/data/ready_data.json",
  wait_between_requests: 1, #sec
  update_interval: 2 #sec

# Print only warnings and errors during test
config :logger, level: :warn
