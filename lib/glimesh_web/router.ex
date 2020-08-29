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
    plug GlimeshWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :fetch_session
    plug :fetch_current_user
    plug :accepts, ["json"]
    plug GlimeshWeb.Plugs.ApiContextPlug
  end

  pipeline :oauth do
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

    post "/token", Oauth2Provider.TokenController, :create
    post "/revoke", Oauth2Provider.TokenController, :revoke
  end

  scope "/api" do
    pipe_through :graphql

    forward "/", Absinthe.Plug, schema: Glimesh.Schema
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

    get "/users/settings/profile", UserSettingsController, :profile
    get "/users/settings/stream", UserSettingsController, :stream
    put "/users/settings/create_channel", UserSettingsController, :create_channel
    put "/users/settings/delete_channel", UserSettingsController, :delete_channel
    get "/users/settings/settings", UserSettingsController, :settings
    put "/users/settings/update_profile", UserSettingsController, :update_profile
    put "/users/settings/update_channel", UserSettingsController, :update_channel

    get "/users/settings/security", UserSecurityController, :index
    put "/users/settings/update_password", UserSecurityController, :update_password
    put "/users/settings/update_email", UserSecurityController, :update_email
    get "/users/settings/confirm_email/:token", UserSecurityController, :confirm_email
    put "/users/settings/update_tfa", UserSecurityController, :update_tfa
    get "/users/settings/get_tfa", UserSecurityController, :get_tfa
    get "/users/settings/tfa_registered", UserSecurityController, :tfa_registered

    get "/oauth/authorize", Oauth2Provider.AuthorizationController, :new
    get "/oauth/authorize/:code", Oauth2Provider.AuthorizationController, :show
    post "/oauth/authorize", Oauth2Provider.AuthorizationController, :create
    delete "/oauth/authorize", Oauth2Provider.AuthorizationController, :delete
  end

  scope "/admin", GlimeshWeb do
    pipe_through [:browser, :require_admin_user]

    import Phoenix.LiveDashboard.Router

    live_dashboard "/phoenix/dashboard", metrics: GlimeshWeb.Telemetry

    live "/platform_subscriptions", PlatformSubscriptionLive.Index, :index

    get "/users/payments", UserPaymentsController, :index
    get "/users/payments/connect", UserPaymentsController, :connect
    put "/users/payments/delete_default_payment", UserPaymentsController, :delete_default_payment

    get "/blog/new", ArticleController, :new
    get "/blog/:slug/edit", ArticleController, :edit
    post "/blog", ArticleController, :create
    patch "/blog/:slug", ArticleController, :update
    put "/blog/:slug", ArticleController, :update
    delete "/blog/:slug", ArticleController, :delete

    live "/categories", Admin.CategoryLive.Index, :index
    live "/categories/new", Admin.CategoryLive.Index, :new
    live "/categories/:id/edit", Admin.CategoryLive.Index, :edit

    live "/categories/:id", Admin.CategoryLive.Show, :show
    live "/categories/:id/show/edit", Admin.CategoryLive.Show, :edit
  end

  scope "/", GlimeshWeb do
    pipe_through [:browser]

    get "/about", AboutController, :index
    get "/about/faq", AboutController, :faq
    get "/about/privacy", AboutController, :privacy
    get "/about/terms", AboutController, :terms

    get "/blog", ArticleController, :index
    get "/blog/:slug", ArticleController, :show

    live "/", HomepageLive, :index
    live "/streams", StreamsLive.List, :index
    live "/streams/:category", StreamsLive.List, :index

    live "/users", UserLive.Index, :index

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm

    # This must be the last route
    live "/:username", UserLive.Stream, :index
    live "/:username/profile", UserLive.Profile, :index
  end
end
