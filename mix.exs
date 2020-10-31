defmodule Glimesh.MixProject do
  use Mix.Project

  def project do
    [
      app: :glimesh,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      {:phx_gen_auth, "~> 0.4.0", only: :dev, runtime: false},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:faker, "~> 0.14", only: :dev},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.0.0", only: :test},
      {:excoveralls, "~> 0.13.1", only: :test},
      {:stripe_mock, "~> 0.1.0", only: :test},
      # Core
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix, "~> 1.5.3"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.14.3"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.2.7"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      # Authentication
      {:comeonin, "~> 5.3"},
      # Email
      {:bamboo, "~> 1.5"},
      # GraphQL API
      {:absinthe, "~> 1.5"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_phoenix, "~> 2.0"},
      {:dataloader, "~> 1.0.0"},
      # HTTP Helpers
      {:plug_canonical_host, "~> 2.0"},
      {:ex_oauth2_provider, "~> 0.5.6"},
      {:slugify, "~> 1.3"},
      {:phoenix_markdown, "~> 1.0"},
      {:html_sanitize_ex, "~> 1.4.1"},
      {:earmark, "~> 1.4"},
      # Uploads
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.9"},
      {:ex_aws, "~> 2.1.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      # Other
      {:hcaptcha, "~> 0.0.1"},
      {:stripity_stripe, "~> 2.0"},
      {:eqrcode, "~> 0.1.7"}
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
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.seed": ["run priv/repo/seeds.#{Mix.env()}.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/seeds/categories.exs",
        "test"
      ],
      code_quality: ["format", "credo --strict"]
    ]
  end
end
