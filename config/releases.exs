# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

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
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

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
    You can generate one by calling: mix phx.gen.secret
    """

url_host = System.get_env("URL_HOST") || raise "environment variable URL_HOST is missing."
url_port = System.get_env("URL_PORT") || raise "environment variable URL_PORT is missing."
url_scheme = System.get_env("URL_SCHEME") || raise "environment variable URL_SCHEME is missing."
http_port = System.get_env("HTTP_PORT") || raise "environment variable URL_PORT is missing."
https_port = System.get_env("HTTPS_PORT") || raise "environment variable URL_PORT is missing."

config :glimesh, GlimeshWeb.Endpoint,
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json",
  canonical_host: url_host,
  url: [
    scheme: url_scheme,
    host: url_host,
    port: url_port
  ],
  secret_key_base: secret_key_base,
  live_view: [signing_salt: live_view_signing_salt]

if http_port !== "" do
  config :glimesh, GlimeshWeb.Endpoint,
    http: [
      port: http_port
    ]
end

if https_port !== "" do
  https_key_file =
    System.get_env("HTTPS_KEY_FILE") || raise "environment variable HTTPS_KEY_FILE is missing."

  https_cert_file =
    System.get_env("HTTPS_CERT_FILE") || raise "environment variable HTTPS_CERT_FILE is missing."

  https_cacert_file =
    System.get_env("HTTPS_CACERT_FILE") ||
      raise "environment variable HTTPS_CACERT_FILE is missing."

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
mailgun_api_key =
  System.get_env("MAILGUN_API_KEY") ||
    raise """
    environment variable MAILGUN_API_KEY is missing.
    """

mailgun_domain =
  System.get_env("MAILGUN_DOMAIN") ||
    raise """
    environment variable MAILGUN_DOMAIN is missing.
    """

config :glimesh, GlimeshWeb.Emails.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: mailgun_api_key,
  domain: mailgun_domain

# Stripe Configuration
stripe_public_api_key =
  System.get_env("STRIPE_PUBLIC_API_KEY") ||
    raise "environment variable STRIPE_PUBLIC_API_KEY is missing."

stripe_api_key =
  System.get_env("STRIPE_API_KEY") || raise "environment variable STRIPE_API_KEY is missing."

stripe_connect_client_id =
  System.get_env("STRIPE_CONNECT_CLIENT_ID") ||
    raise "environment variable STRIPE_CONNECT_CLIENT_ID is missing."

stripe_webhook_secret =
  System.get_env("STRIPE_WEBHOOK_SECRET") ||
    raise "environment variable STRIPE_WEBHOOK_SECRET is missing."

config :stripity_stripe,
  public_api_key: stripe_public_api_key,
  api_key: stripe_api_key,
  connect_client_id: stripe_connect_client_id,
  webhook_secret: stripe_webhook_secret

# hCaptcha Configuration
hcaptcha_public_key =
  System.get_env("HCAPTCHA_PUBLIC_KEY") ||
    raise "environment variable HCAPTCHA_PUBLIC_KEY is missing."

hcaptcha_secret =
  System.get_env("HCAPTCHA_SECRET") ||
    raise "environment variable HCAPTCHA_SECRET is missing."

config :hcaptcha,
  public_key: hcaptcha_public_key,
  secret: hcaptcha_secret

# Waffle Configuration
do_spaces_public_key =
  System.get_env("DO_SPACES_PUBLIC_KEY") ||
    raise "environment variable DO_SPACES_PUBLIC_KEY is missing."

do_spaces_private_key =
  System.get_env("DO_SPACES_PRIVATE_KEY") ||
    raise "environment variable DO_SPACES_PRIVATE_KEY is missing."

do_spaces_bucket =
  System.get_env("DO_SPACES_BUCKET") ||
    raise "environment variable DO_SPACES_BUCKET is missing."

waffle_asset_host =
  System.get_env("WAFFLE_ASSET_HOST") ||
    raise "environment variable WAFFLE_ASSET_HOST is missing."

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

# Glimesh Configuration
email_physical_address =
  System.get_env("GLIMESH_EMAIL_PHYSICAL_ADDRESS") ||
    raise "environment variable GLIMESH_EMAIL_PHYSICAL_ADDRESS is missing."

config :glimesh,
  email_physical_address: email_physical_address

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
  channel_sub_base_price: 500
