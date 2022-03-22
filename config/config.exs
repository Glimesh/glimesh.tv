# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

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
  "Norsk Nynorsk": "nn",
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
  locales: locales,
  privacy_policy_version: ~N[2022-03-21 11:55:00]

config :glimesh, Glimesh.Repo, prepare: :unnamed
config :glimesh, Glimesh.Repo.ReadReplica, prepare: :unnamed

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.39.0",
  default: [
    args: ~w(--load-path=./node_modules css/app.scss ../priv/static/css/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

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

config :boruta, Boruta.Oauth,
  repo: Glimesh.Repo,
  cache_backend: Boruta.Cache,
  contexts: [
    access_tokens: Boruta.Ecto.AccessTokens,
    clients: Boruta.Ecto.Clients,
    codes: Boruta.Ecto.Codes,
    # mandatory for user flows
    resource_owners: Glimesh.Oauth.ResourceOwners,
    scopes: Boruta.Ecto.Scopes
  ],
  max_ttl: [
    authorization_code: 60,
    access_token: 60 * 60 * 24,
    refresh_token: 60 * 60 * 24 * 30
  ],
  token_generator: Boruta.TokenGenerator

config :boruta, Boruta.Cache,
  primary: [
    # => 1 day
    gc_interval: :timer.hours(6),
    backend: :shards,
    partitions: 2
  ]

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
    Kenya: "KE",
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
    Philippines: "PH",
    Poland: "PL",
    Portugal: "PT",
    Romania: "RO",
    "Saudi Arabia": "SA",
    Singapore: "SG",
    Slovakia: "SK",
    Slovenia: "SI",
    "South Africa": "ZA",
    Spain: "ES",
    Sweden: "SE",
    Switzerland: "CH",
    Thailand: "TH",
    Turkey: "TR",
    "Trinidad & Tobago": "TT",
    "United Kingdom of Great Britain and Northern Ireland": "GB",
    "United States of America": "US",
    Uruguay: "UY"
  ]

config :glimesh, :pronouns,
  pronouns: [
    None: "None",
    "Ar/Aer": "Ae/Aer",
    "E/Em": "E/Em",
    "Fae/Faer": "Fae/Faer",
    "He/Him": "He/Him",
    "He/She": "He/She",
    "He/They": "He/They",
    "It/Its": "It/Its",
    Other: "Other",
    "Per/Per": "Per/Per",
    "She/Her": "She/Her",
    "She/They": "She/They",
    "They/Them": "They/Them",
    "They/He": "They/He",
    "They/She": "They/She",
    "Ve/Ver": "Ve/Ver",
    "Xe/Xem": "Xe/Xem",
    "Zie/Hir": "Zie/Hir"
  ]

# Configuration for the Event System
config :glimesh, :event_type,
  event_labels: [
    nil: "-",
    "GCT Event": "GCT Event",
    "Community Event": "Community Event",
    "Glimesh Event": "Glimesh Event"
  ],
  event_colors: [
    "GCT Event": "var(--success)",
    "Community Event": "#00AFEF",
    "Glimesh Event": "var(--danger)"
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

config :sentry,
  dsn: "",
  environment_name: :dev,
  included_environments: [:prod]

config :phoenix_markdown, :server_tags, only: ["privacy.html", "cookies.html", "terms.html"]

import_config "badwords.exs"
import_config "emotes.exs"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
