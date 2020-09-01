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
  # or {:system, "MAILGUN_API_KEY"},
  api_key: "my_api_key",
  # or {:system, "MAILGUN_DOMAIN"},
  domain: "your.domain",
  hackney_opts: [recv_timeout: :timer.minutes(1)]

config :glimesh, GlimeshWeb.Gettext,
  default_locale: "en",
  locales: ~w(en es ja de nb es_MX es_AR fr sv vi ru)

config :ex_oauth2_provider, namespace: Glimesh
config :ex_oauth2_provider, ExOauth2Provider,
  repo: Glimesh.Repo,
  resource_owner: Glimesh.Accounts.User,
  use_refresh_token: true,
  revoke_refresh_token_on_use: true,
  default_scopes: ~w(public),
  optional_scopes: ~w(email chat),
  authorization_code_expires_in: 600,
  access_token_expires_in: 21600,
  grant_flows: ~w(authorization_code client_credentials implicit_grant)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

config :stripity_stripe,
  api_key: "YOUR SECRET KEY",
  public_api_key: "YOUR PUBLIC KEY",
  connect_client_id: "YOUR CLIENT ID",
  webhook_secret: "YOUR WEBHOOK SECRET"

import_config "badwords.exs"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
