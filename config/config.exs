# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :airlock,
  ecto_repos: [Airlock.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :airlock, AirlockWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zOGU0d4mlTl84uoQTmnkqN3urt6uARWovDwpXtXCPBtPBrf3o1562cXz1REATfUi",
  render_errors: [view: AirlockWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Airlock.PubSub,
  live_view: [signing_salt: "Zhx3dcGM"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
