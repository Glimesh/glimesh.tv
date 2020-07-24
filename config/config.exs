# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :glimesh,
  ecto_repos: [Glimesh.Repo],
  environment: Mix.env()

config :waffle,
  storage: Waffle.Storage.Local,
  storage_dir: "uploads"

# Configures the endpoint
config :glimesh, GlimeshWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BTYMVSu3uDTxP4vZCJfduugXrRBWVUzOOPFLdYTQZ39cqqPFlrKNSyvxa+C/1PjN",
  render_errors: [view: GlimeshWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Glimesh.PubSub,
  live_view: [signing_salt: "SMbzIesWtn1j3jn3ltuP/bxYkKmEhedC"]

config :glimesh, GlimeshWeb.Emails.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: "my_api_key", # or {:system, "MAILGUN_API_KEY"},
  domain: "your.domain", # or {:system, "MAILGUN_DOMAIN"},
  hackney_opts: [recv_timeout: :timer.minutes(1)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
       md: PhoenixMarkdown.Engine

config :stripity_stripe, api_key: "YOUR SECRET KEY"

import_config "badwords.exs"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
