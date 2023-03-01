[
  import_deps: [:ecto, :ecto_sql, :phoenix, :surface],
  plugins: [Phoenix.LiveView.HTMLFormatter, Surface.Formatter.Plugin],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs,sface}", "priv/*/seeds.exs"],
  subdirectories: ["priv/*/migrations"]
]
