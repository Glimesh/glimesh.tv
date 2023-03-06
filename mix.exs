defmodule Glimesh.MixProject do
  use Mix.Project

  def project do
    [
      app: :glimesh,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Glimesh.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Dev & Test Libs
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.0.0", only: :test},
      {:excoveralls, "~> 0.13.1", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test},
      # Core
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.18.16"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_html, "~> 3.3"},
      {:surface, "~> 0.9.4"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ecto_psql_extras, "~> 0.2"},
      {:oban, "~> 2.13"},
      # Authentication & Authorization
      {:comeonin, "~> 5.3"},
      {:bodyguard, "~> 2.4"},
      # Email
      {:swoosh, "~> 1.3"},
      {:bamboo, "~> 1.5"},
      # GraphQL API
      {:absinthe, "~> 1.5"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_relay, "~> 1.5"},
      {:dataloader, "~> 1.0.0"},
      # HTTP Helpers
      {:plug_canonical_host, "~> 2.0"},
      {:boruta, "~> 2.1.5"},
      {:slugify, "~> 1.3"},
      {:phoenix_markdown, "~> 1.0"},
      {:html_sanitize_ex, "~> 1.4.1"},
      {:earmark, "~> 1.4"},
      {:oauther, "~> 1.3"},
      {:oauth2, "~> 2.0"},
      {:extwitter, "~> 0.13"},
      {:navigation_history, "~> 0.4"},
      # Uploads
      {:waffle, "~> 1.1"},
      {:waffle_ecto,
       git: "https://github.com/nash-io/waffle_ecto.git",
       ref: "8fac195e2ee36a2383df0ee8e8787c2e88d86ff8"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.17"},
      {:sweet_xml, "~> 0.6"},
      {:ex_image_info, "~> 0.2.4"},
      # Other
      {:heroicons, "~> 0.5"},
      {:sentry, "~> 8.0"},
      {:prom_ex, "~> 1.3"},
      {:hcaptcha, "~> 0.0.1"},
      {:stripity_stripe, "~> 2.12"},
      {:eqrcode, "~> 0.1.7"},
      {:scrivener_ecto, "~> 2.0"},
      {:libcluster, "~> 3.2"},
      {:httpoison, "~> 1.8"},
      {:con_cache, "~> 1.0"},
      {:tzdata, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.seed": ["run priv/repo/seeds.#{Mix.env()}.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/seeds/categories.exs",
        "run priv/repo/seeds/scopes.exs",
        "test"
      ],
      code_quality: ["format", "credo --strict"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest priv/static -o priv/public"
      ]
    ]
  end
end
