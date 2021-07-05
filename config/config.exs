# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# This will manually need to be populated as languages are completed.
# Format: Displayname: "locale_code"
locales = [
  English: "en",
  Español: "es",
  "Español rioplatense": "es_AR",
  "Español mexicano": "es_MX",
  Deutsch: "de",
  日本語: "ja",
  "Norsk Bokmål": "nb",
  Français: "fr",
  Svenska: "sv",
  "Tiếng Việt": "vi",
  Русский: "ru",
  한국어: "ko",
  Italiano: "it",
  български: "bg",
  Nederlands: "nl",
  Suomi: "fi",
  Polski: "pl",
  "Limba Română": "ro",
  "Português Brasileiro": "pt_br",
  Português: "pt",
  "中文 (简体)": "zh_Hans",
  "中文 (繁体)": "zh_Hant",
  "العامية المصرية": "ar_eg",
  čeština: "cs",
  Dansk: "da",
  "Magyar Nyelv": "hu",
  Gaeilge: "ga",
  slovenščina: "sl",
  Türkçe: "tr"
]

config :glimesh,
  ecto_repos: [Glimesh.Repo],
  environment: Mix.env(),
  email_physical_address: "1234 Fake St.<br>Pittsburgh, PA 15217",
  alpha_api_enable: true,
  locales: locales

config :glimesh, Glimesh.Repo, prepare: :unnamed

config :waffle,
  storage: Waffle.Storage.Local,
  storage_dir: "uploads",
  version_timeout: 4_000

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
  locales: Enum.map(locales, fn {_, x} -> x end),
  one_module_per_locale: true

config :ex_oauth2_provider, namespace: Glimesh

config :ex_oauth2_provider, ExOauth2Provider,
  repo: Glimesh.Repo,
  resource_owner: Glimesh.Accounts.User,
  use_refresh_token: true,
  revoke_refresh_token_on_use: true,
  default_scopes: ~w(public),
  optional_scopes: ~w(email chat streamkey),
  authorization_code_expires_in: 600,
  access_token_expires_in: 21600,
  grant_flows: ~w(authorization_code client_credentials implicit_grant),
  force_ssl_in_redirect_uri: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

config :postgrex, :json_library, Jason

config :stripity_stripe,
  api_key: "sk_test_123",
  public_api_key: "YOUR PUBLIC KEY",
  connect_client_id: "YOUR CLIENT ID",
  webhook_secret: "YOUR WEBHOOK SECRET"

config :glimesh, :stripe_config,
  platform_sub_supporter_price: 500,
  platform_sub_founder_price: 2500,
  channel_sub_base_price: 500,
  payout_countries: [
    Argentina: "AR",
    Australia: "AU",
    Austria: "AT",
    Belgium: "BE",
    Bolivia: "BO",
    Brazil: "BR",
    Bulgaria: "BG",
    Canada: "CA",
    Chile: "CL",
    Colombia: "CO",
    "Costa Rica": "CR",
    Croatia: "HR",
    Cyprus: "CY",
    Czechia: "CZ",
    Denmark: "DK",
    "Dominican Republic": "DO",
    Egypt: "EG",
    Estonia: "EE",
    Finland: "FI",
    France: "FR",
    Germany: "DE",
    Greece: "GR",
    "Hong Kong": "HK",
    Hungary: "HU",
    Iceland: "IS",
    India: "IN",
    Indonesia: "ID",
    Ireland: "IE",
    Israel: "IL",
    Italy: "IT",
    Latvia: "LV",
    Liechtenstein: "LI",
    Lithuania: "LT",
    Luxembourg: "LU",
    Malta: "MT",
    Mexico: "MX",
    Netherlands: "NL",
    "New Zealand": "NZ",
    Norway: "NO",
    Paraguay: "PY",
    Peru: "PE",
    Poland: "PL",
    Portugal: "PT",
    Romania: "RO",
    Singapore: "SG",
    Slovakia: "SK",
    Slovenia: "SI",
    Spain: "ES",
    Sweden: "SE",
    Switzerland: "CH",
    Thailand: "TH",
    "Trinidad & Tobago": "TT",
    "United Kingdom of Great Britain and Northern Ireland": "GB",
    "United States of America": "US",
    Uruguay: "UY"
  ]

config :hcaptcha,
  public_key: "10000000-ffff-ffff-ffff-000000000001",
  secret: "0x0000000000000000000000000000000000000000"

config :glimesh, Glimesh.Socials.Twitter,
  consumer_key: "",
  consumer_secret: "",
  access_token: "",
  access_token_secret: ""

config :glimesh, Glimesh.Emotes, max_channel_emotes: 10, allow_channel_animated_emotes: true

config :libcluster,
  topologies: []

config :rihanna,
  producer_postgres_connection: {Ecto, Glimesh.Repo}

config :glimesh, Glimesh.PaymentProviders.TaxIDPro, webhook_secret: "", api_key: ""

config :glimesh, Glimesh.PromEx, disabled: true

import_config "badwords.exs"
import_config "emotes.exs"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
