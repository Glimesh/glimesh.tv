# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

# Node configuration
if System.get_env("ENABLE_LIBCLUSTER") do
  config :libcluster,
    topologies: [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"glimesh@do-nyc3-web1.us-east.web.glimesh.tv",
            :"glimesh@do-nyc3-web2.us-east.web.glimesh.tv",
            :"glimesh@do-nyc3-web3.us-east.web.glimesh.tv"
          ]
        ]
      ]
    ]
end

# Database Configuration
database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :glimesh, Glimesh.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

config :glimesh, Glimesh.Repo.ReadReplica,
  # ssl: true,
  # Fallback to regular database if we don't want a read database
  url: System.get_env("READ_DATABASE_URL", database_url),
  pool_size: String.to_integer(System.get_env("READ_POOL_SIZE", "10"))

# Endpoint Configuration
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

live_view_signing_salt =
  System.get_env("LIVE_VIEW_SIGNING_SALT") ||
    raise """
    environment variable LIVE_VIEW_SIGNING_SALT is missing.
    You can generate one by calling: mix phx.gen.secret 32
    """

url_host = System.fetch_env!("URL_HOST")
url_port = System.fetch_env!("URL_PORT")
url_scheme = System.fetch_env!("URL_SCHEME")

config :glimesh, GlimeshWeb.Endpoint,
  server: true,
  cache_static_manifest: "priv/public/cache_manifest.json",
  canonical_host: url_host,
  url: [
    scheme: url_scheme,
    host: url_host,
    port: url_port
  ],
  secret_key_base: secret_key_base,
  live_view: [signing_salt: live_view_signing_salt]

if http_port = System.get_env("HTTP_PORT") do
  config :glimesh, GlimeshWeb.Endpoint,
    http: [
      port: http_port
    ]
end

if https_port = System.get_env("HTTPS_PORT") do
  https_key_file = System.fetch_env!("HTTPS_KEY_FILE")
  https_cert_file = System.fetch_env!("HTTPS_CERT_FILE")
  https_cacert_file = System.fetch_env!("HTTPS_CACERT_FILE")

  config :glimesh, GlimeshWeb.Endpoint,
    https: [
      port: https_port,
      cipher_suite: :strong,
      keyfile: https_key_file,
      certfile: https_cert_file,
      cacertfile: https_cacert_file,
      transport_options: [socket_opts: [:inet6]]
    ]
end

# Email Configuration
if mailgun_api_key = System.get_env("MAILGUN_API_KEY") do
  mailgun_domain = System.fetch_env!("MAILGUN_DOMAIN")

  config :glimesh, GlimeshWeb.Emails.Mailer,
    adapter: Bamboo.MailgunAdapter,
    api_key: mailgun_api_key,
    domain: mailgun_domain
end

# Stripe Configuration
stripe_public_api_key = System.fetch_env!("STRIPE_PUBLIC_API_KEY")
stripe_api_key = System.fetch_env!("STRIPE_API_KEY")
stripe_connect_client_id = System.fetch_env!("STRIPE_CONNECT_CLIENT_ID")
stripe_webhook_secret = System.fetch_env!("STRIPE_WEBHOOK_SECRET")

config :stripity_stripe,
  public_api_key: stripe_public_api_key,
  api_key: stripe_api_key,
  connect_client_id: stripe_connect_client_id,
  webhook_secret: stripe_webhook_secret

# hCaptcha Configuration
if hcaptcha_public_key = System.get_env("HCAPTCHA_PUBLIC_KEY") do
  hcaptcha_secret = System.fetch_env!("HCAPTCHA_SECRET")

  config :hcaptcha,
    public_key: hcaptcha_public_key,
    secret: hcaptcha_secret
end

# Waffle Configuration
if System.get_env("WAFFLE_ENDPOINT") == "S3" do
  do_spaces_public_key = System.fetch_env!("DO_SPACES_PUBLIC_KEY")
  do_spaces_private_key = System.fetch_env!("DO_SPACES_PRIVATE_KEY")
  do_spaces_bucket = System.fetch_env!("DO_SPACES_BUCKET")
  waffle_asset_host = System.fetch_env!("WAFFLE_ASSET_HOST")

  config :waffle,
    storage: Waffle.Storage.S3,
    bucket: do_spaces_bucket,
    asset_host: waffle_asset_host

  config :ex_aws,
    access_key_id: do_spaces_public_key,
    secret_access_key: do_spaces_private_key,
    region: "us-east-1",
    s3: [
      scheme: "https://",
      host: "nyc3.digitaloceanspaces.com",
      region: "us-east-1"
    ]
end

# Twitter Config
if twitter_consumer_key = System.get_env("TWITTER_CONSUMER_KEY") do
  twitter_consumer_secret = System.fetch_env!("TWITTER_CONSUMER_SECRET")
  twitter_access_token = System.fetch_env!("TWITTER_ACCESS_TOKEN")
  twitter_access_secret = System.fetch_env!("TWITTER_ACCESS_SECRET")

  config :glimesh, Glimesh.Socials.Twitter,
    consumer_key: twitter_consumer_key,
    consumer_secret: twitter_consumer_secret,
    access_token: twitter_access_token,
    access_token_secret: twitter_access_secret
end

if sentry_dsn = System.get_env("SENTRY_DSN") do
  config :sentry,
    dsn: sentry_dsn,
    environment_name: :prod,
    release: to_string(Glimesh.get_version()),
    server_name: to_string(node()),
    enable_source_code_context: true,
    root_source_code_path: File.cwd!(),
    tags: %{
      env: "prod"
    },
    included_environments: [:prod]

  config :logger,
    level: :info,
    backends: [:console, Sentry.LoggerBackend]
end

# Twitter Config
if taxidpro_api_key = System.get_env("TAXIDPRO_API_KEY") do
  taxidpro_webhook_secret = System.fetch_env!("TAXIDPRO_WEBHOOK_SECRET")

  config :glimesh, Glimesh.PaymentProviders.TaxIDPro,
    webhook_secret: taxidpro_webhook_secret,
    api_key: taxidpro_api_key
end

# Rawg Config
if rawg_api_key = System.get_env("RAWG_API_KEY") do
  config :glimesh, Glimesh.Subcategories.RawgSource, api_key: rawg_api_key
end

# PromEx Config
if System.get_env("ENABLE_PROMEX") do
  promex_auth_token = System.fetch_env!("PROMEX_AUTH_TOKEN")
  grafana_host = System.fetch_env!("GRAFANA_HOST")
  grafana_auth_token = System.fetch_env!("GRAFANA_AUTH_TOKEN")

  config :glimesh, Glimesh.PromEx,
    disabled: false,
    manual_metrics_start_delay: :no_delay,
    drop_metrics_groups: [],
    grafana: [
      host: grafana_host,
      auth_token: grafana_auth_token,
      upload_dashboards_on_start: true,
      annotate_app_lifecycle: true
    ],
    metrics_server: [
      port: 4021,
      path: "/metrics",
      protocol: :http,
      pool_size: 5,
      cowboy_opts: [],
      auth_strategy: :bearer,
      auth_token: promex_auth_token
    ]
else
  config :glimesh, Glimesh.PromEx, disabled: true
end

# Glimesh Configuration
if email_physical_address = System.get_env("GLIMESH_EMAIL_PHYSICAL_ADDRESS") do
  config :glimesh,
    email_physical_address: email_physical_address
end

if show_staging_warning = System.get_env("GLIMESH_SHOW_STAGING_WARNING") do
  config :glimesh,
    show_staging_warning: show_staging_warning
end

if max_emotes = System.get_env("GLIMESH_MAX_CHANNEL_EMOTES") do
  {max, _} = Integer.parse(max_emotes)
  config :glimesh, Glimesh.Emotes, max_channel_emotes: max
end

if allow_animated_emotes = System.get_env("GLIMESH_ALLOW_CHANNEL_ANIMATED_EMOTES") do
  config :glimesh, Glimesh.Emotes, allow_channel_animated_emotes: true
end

if tiltify_access_token = System.get_env("GLIMESH_TILTIFY_ACCESS_TOKEN") do
  config :glimesh, tiltify_access_token: tiltify_access_token
end

# Default App Config
config :glimesh, :stripe_config,
  platform_sub_supporter_product_id: "prod_I60rR8YatfJpEV",
  platform_sub_supporter_price_id: "price_1HVoq1BLNaYgaiU5EMayvTwj",
  platform_sub_supporter_price: 500,
  platform_sub_founder_product_id: "prod_I60rQdgrge5imp",
  platform_sub_founder_price_id: "price_1HVopMBLNaYgaiU5drbv5cVL",
  platform_sub_founder_price: 2500,
  channel_sub_base_product_id: "prod_I60qVBVw8n1Y1e",
  channel_sub_base_price_id: "price_1HVoopBLNaYgaiU5r5JTEEoj",
  channel_sub_base_price: 500,
  channel_donation_product_id: "prod_KXgBrHAjDHTJLf"
