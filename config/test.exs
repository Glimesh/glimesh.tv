use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :glimesh, Glimesh.Repo,
  username: "postgres",
  password: "postgres",
  database: "glimesh_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :glimesh, GlimeshWeb.Endpoint,
  http: [port: 4002],
  server: false

config :glimesh, GlimeshWeb.Emails.Mailer, adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn

config :stripity_stripe, :api_base_url, "http://localhost:12111/v1/"
config :stripe_mock, StripeMockWeb.Endpoint, http: [port: 12111], server: true

config :hcaptcha,
  http_client: Hcaptcha.Http.MockClient,
  secret: "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"

config :glimesh, :stripe_config,
  platform_sub_supporter_product_id: "prod_platform_supporter",
  platform_sub_supporter_price_id: "price_platform_supporter",
  platform_sub_supporter_price: 500,
  platform_sub_founder_product_id: "prod_platform_founder",
  platform_sub_founder_price_id: "price_platform_founder",
  platform_sub_founder_price: 2500,
  channel_sub_base_product_id: "prod_channel_sub",
  channel_sub_base_price_id: "price_channel_sub",
  channel_sub_base_price: 500

config :appsignal, :config, active: false
