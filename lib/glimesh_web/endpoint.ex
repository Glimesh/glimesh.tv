defmodule GlimeshWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :glimesh

  # The session will be stored in the cookie: signed & encrypted.
  # The value used for encryption is our `secret_key_base`
  @session_options [
    store: :cookie,
    key: "_glimesh_key",
    signing_salt: Application.get_env(:glimesh, GlimeshWeb.Endpoint)[:live_view][:signing_salt]
  ]

  # Redirect to primary domain before doing anything
  plug :canonical_host

  socket "/socket", GlimeshWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :glimesh,
    gzip: false,
    only:
      ~w(css fonts images videos js ovenplayer cache_manifest.json favicons browserconfig.xml favicon.ico robots.txt site.webmanifest)

  plug Plug.Static, at: "/uploads", from: Application.get_env(:waffle, :storage_dir)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :glimesh
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    #    body_reader: {GlimeshWeb.BodySaver, :read_body, []},
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug GlimeshWeb.Router

  defp canonical_host(conn, _opts) do
    case Application.get_env(:glimesh, GlimeshWeb.Endpoint)[:canonical_host] do
      host when is_binary(host) ->
        opts = PlugCanonicalHost.init(canonical_host: host)
        PlugCanonicalHost.call(conn, opts)

      _ ->
        conn
    end
  end
end
