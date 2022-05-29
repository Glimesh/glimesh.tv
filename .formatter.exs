[
  import_deps: [:ecto, :phoenix, :surface],
  plugins: [Phoenix.LiveView.HTMLFormatter, Surface.Formatter.Plugin],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs,sface}", "priv/*/seeds.exs"],
  subdirectories: ["priv/*/migrations"]
]
