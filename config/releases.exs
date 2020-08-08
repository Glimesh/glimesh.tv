# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

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

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :glimesh, GlimeshWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
