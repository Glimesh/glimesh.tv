defmodule GlimeshWeb.Router do
  use GlimeshWeb, :router

  import GlimeshWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GlimeshWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug GlimeshWeb.Plugs.Floc
    plug GlimeshWeb.Plugs.Locale
    plug GlimeshWeb.Plugs.CfCountryPlug
    plug GlimeshWeb.Plugs.Ban
    plug GlimeshWeb.Plugs.UserAgent
    plug GlimeshWeb.UniqueUserPlug
    plug NavigationHistory.Tracker, excluded_paths: ["/users/log_in", "/users/register"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql_alpha_api do
    plug :accepts, ["json"]
    # This route does not use session / cookies, so CORS can be wide open
    plug GlimeshWeb.Plugs.Cors
    plug :require_alpha_api_header
    plug GlimeshWeb.Plugs.ApiContextPlug
  end

  pipeline :graphql do
    plug :fetch_session
    plug :fetch_current_user
    plug :accepts, ["json"]
    plug GlimeshWeb.Plugs.OldApiContextPlug
  end

  pipeline :oauth do
    # This route does not use session / cookies, so CORS can be wide open
    plug GlimeshWeb.Plugs.Cors
    plug Plug.Parsers, parsers: [:urlendoded]
  end

  if Mix.env() in [:dev, :test] do
    scope "/" do
      pipe_through :browser

      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end

  scope "/api/oauth", GlimeshWeb do
    pipe_through :oauth

    post "/token", OauthController, :token
    post "/revoke", OauthController, :revoke
    post "/introspect", OauthController, :introspect
  end

  scope "/api/webhook", GlimeshWeb do
    pipe_through :api

    # post "/stripe", WebhookController, :stripe
    post "/taxidpro", WebhookController, :taxidpro
  end

  scope "/api/graph" do
    pipe_through :graphql_alpha_api

    forward "/", Glimesh.Api.GraphiQLPlug,
      schema: Glimesh.Api.Schema,
      socket: GlimeshWeb.GraphApiSocket,
      default_url: {__MODULE__, :graph_default_url},
      socket_url: {__MODULE__, :graph_socket_url},
      interface: :playground,
      analyze_complexity: true,
      max_complexity: 500
  end

  scope "/api" do
    pipe_through :graphql

    forward "/", Absinthe.Plug.GraphiQL,
      schema: Glimesh.OldSchema,
      socket: GlimeshWeb.OldApiSocket,
      default_url: {__MODULE__, :graphiql_default_url},
      socket_url: {__MODULE__, :graphiql_socket_url}
  end

  ## Authentication routes
  scope "/", GlimeshWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    post "/users/log_in_tfa", UserSessionController, :tfa
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", GlimeshWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/about/privacy", AboutController, :accept_privacy

    live "/platform_subscriptions", PlatformSubscriptionLive.Index, :index

    get "/users/social/twitter", UserSocialController, :twitter
    delete "/users/social/disconnect/:platform", UserSocialController, :disconnect

    get "/users/payments", UserPaymentsController, :index
    post "/users/payments/setup", UserPaymentsController, :setup
    get "/users/payments/taxes", UserPaymentsController, :taxes
    get "/users/payments/taxes_pending", UserPaymentsController, :taxes_pending
    get "/users/payments/connect", UserPaymentsController, :connect
    put "/users/payments/delete_default_payment", UserPaymentsController, :delete_default_payment

    get "/users/settings/profile", UserSettingsController, :profile
    get "/users/settings/stream", UserSettingsController, :stream

    get "/users/settings/channel_statistics", UserSettingsController, :channel_statistics
    get "/users/settings/addons", UserSettingsController, :addons
    get "/users/settings/emotes", UserSettingsController, :emotes
    get "/users/settings/upload_emotes", UserSettingsController, :upload_emotes
    get "/users/settings/hosting", UserSettingsController, :hosting

    put "/users/settings/create_channel", UserSettingsController, :create_channel
    put "/users/settings/delete_channel", UserSettingsController, :delete_channel
    get "/users/settings/preference", UserSettingsController, :preference
    put "/users/settings/preference", UserSettingsController, :update_preference
    put "/users/settings/update_profile", UserSettingsController, :update_profile
    put "/users/settings/update_channel", UserSettingsController, :update_channel
    get "/users/settings/notifications", UserSettingsController, :notifications

    get "/users/settings/security", UserSecurityController, :index
    put "/users/settings/update_password", UserSecurityController, :update_password
    put "/users/settings/update_email", UserSecurityController, :update_email
    get "/users/settings/confirm_email/:token", UserSecurityController, :confirm_email
    put "/users/settings/update_tfa", UserSecurityController, :update_tfa
    get "/users/settings/get_tfa", UserSecurityController, :get_tfa
    get "/users/settings/tfa_registered", UserSecurityController, :tfa_registered

    put "/users/settings/applications/:id/rotate", UserApplicationsController, :rotate
    resources "/users/settings/applications", UserApplicationsController

    resources "/users/settings/authorizations", UserAuthorizedAppsController,
      only: [:index, :delete],
      param: "id"

    get "/oauth/authorize", OauthController, :authorize
    post "/oauth/authorize", OauthController, :process_authorize
  end

  scope "/", GlimeshWeb do
    pipe_through [:browser, :require_authenticated_user, :require_user_has_channel]

    post "/users/settings/channel/mods/ban_user",
         ChannelModeratorController,
         :ban_user

    delete "/users/settings/channel/mods/unban_user/:username",
           ChannelModeratorController,
           :unban_user

    resources "/users/settings/channel/mods", ChannelModeratorController
  end

  scope "/admin", GlimeshWeb do
    pipe_through [:browser, :require_admin_user]

    import Phoenix.LiveDashboard.Router

    live_dashboard "/phoenix/dashboard", metrics: GlimeshWeb.Telemetry, ecto_repos: [Glimesh.Repo]

    live "/categories", Admin.CategoryLive.Index, :index
    live "/categories/new", Admin.CategoryLive.Index, :new
    live "/categories/:id/edit", Admin.CategoryLive.Index, :edit

    live "/categories/:id", Admin.CategoryLive.Show, :show
    live "/categories/:id/show/edit", Admin.CategoryLive.Show, :edit

    live "/tags", Admin.TagLive.Index, :index
    live "/tags/new", Admin.TagLive.Index, :new
    live "/tags/:id/edit", Admin.TagLive.Index, :edit
  end

  scope "/gct", GlimeshWeb do
    pipe_through [:browser, :require_gct_user]

    get "/", GctController, :index
    get "/me", GctController, :edit_self
    get "/unauthorized", GctController, :unauthorized

    # Lookup scopes
    get "/lookup/user", GctController, :username_lookup
    get "/lookup/channel", GctController, :channel_lookup
    get "/lookup/channel/:channel_id/chat", GctController, :channel_chat_log
    get "/lookup/user/:user_id/chat", GctController, :user_chat_log

    # Editing profile scopes
    get "/edit/profile/:username", GctController, :edit_user_profile
    put "/edit/profile/:username/update", GctController, :update_user_profile

    # Editing user scopes
    get "/edit/:username", GctController, :edit_user
    put "/edit/:username/update", GctController, :update_user

    # Editing channel scopes
    get "/edit/channel/:channel_id", GctController, :edit_channel
    post "/edit/channel/:channel_id/shutdown", GctController, :shutdown_channel
    put "/edit/channel/:channel_id/update", GctController, :update_channel
    put "/edit/channel/:channel_id/delete", GctController, :delete_channel

    # Audit log
    get "/audit-log", GctController, :audit_log

    # Emote scopes
    get "/global-emotes", GctController, :global_emotes
    get "/review-emotes", GctController, :review_emotes

    # Categories and subcategories and tags and probably more
  end

  scope "/", GlimeshWeb do
    pipe_through [:browser, :require_events_team_user]

    live "/events/admin", Events.EventsAdminLive, :index
  end

  scope "/", GlimeshWeb do
    pipe_through [:browser]

    get "/about", AboutController, :index
    get "/about/streaming", AboutController, :streaming
    get "/about/team", AboutController, :team
    get "/about/mission", AboutController, :mission
    get "/about/alpha", AboutController, :alpha
    get "/about/faq", AboutController, :faq
    get "/about/privacy", AboutController, :privacy
    get "/about/terms", AboutController, :terms
    get "/about/conduct", AboutController, :conduct
    get "/about/credits", AboutController, :credits
    get "/about/cookies", AboutController, :cookies
    get "/about/dmca", AboutController, :dmca

    live "/about/open-data", About.OpenDataLive, :index
    live "/about/open-data/subscriptions", About.OpenDataLive, :subscriptions
    live "/about/open-data/streams", About.OpenDataLive, :streams

    live "/about/app", About.AppLive, :index

    live "/events", EventsLive, :index

    get "/blog", BlogMigrationController, :redirect_blog
    get "/blog/:slug", BlogMigrationController, :redirect_post

    live "/", HomepageLive, :index
    live "/streams", StreamsLive.Index, :index
    live "/streams/following", StreamsLive.Following, :index
    live "/streams/:category", StreamsLive.List, :index

    live "/users", UserLive.Index, :index

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm

    post "/quick_preferences", QuickPreferenceController, :update_preference

    # Short Links
    get "/s/event-form", ShortLinkController, :event_form
    get "/s/discord", ShortLinkController, :community_discord

    # This must be the last route
    live "/:username", UserLive.Stream, :index
    get "/:username/interactive", InteractiveController, :index
    live "/:username/support", UserLive.Stream, :support
    live "/:username/support/:tab", UserLive.Stream, :support
    live "/:username/profile", UserLive.Profile, :index
    live "/:username/profile/followers", UserLive.Followers, :followers
    live "/:username/profile/following", UserLive.Followers, :following
    live "/:username/chat", ChatLive.PopOut, :index
  end

  alias GlimeshWeb.Router.Helpers, as: Routes

  def graphiql_default_url(conn) do
    Routes.url(conn) <> "/api"
  end

  def graphiql_socket_url(conn) do
    (Routes.url(conn) <> "/api/socket")
    |> String.replace("http", "ws")
    |> String.replace("https", "wss")
  end

  def graph_default_url(conn) do
    Routes.url(conn) <> "/api/graph"
  end

  def graph_socket_url(conn) do
    (Routes.url(conn) <> "/api/graph/socket")
    |> String.replace("http", "ws")
    |> String.replace("https", "wss")
  end
end
