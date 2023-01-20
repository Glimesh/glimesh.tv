defmodule GlimeshWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use GlimeshWeb, :controller
      use GlimeshWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do:
      ~w(emotes fa-fonts favicons fonts images css js browserconfig.xml cache_manifest.json favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import GlimeshWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: GlimeshWeb,
        formats: [:html, :json],
        layouts: [html: GlimeshWeb.Layouts]

      import Plug.Conn
      import GlimeshWeb.Gettext

      alias GlimeshWeb.Router.Helpers, as: Routes
      import Glimesh.Formatters

      def unauthorized(conn) do
        conn
        |> put_status(403)
        |> send_resp(403, "Unauthorized")
        |> halt()
      end

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/glimesh_web/templates",
        namespace: GlimeshWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [
          get_flash: 1,
          get_flash: 2,
          view_module: 1,
          view_template: 1,
          action_name: 1,
          controller_module: 1
        ]

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def user_settings_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {GlimeshWeb.Layouts, :user_sidebar}

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {GlimeshWeb.Layouts, :app}

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def surface_live_view do
    quote do
      use Surface.LiveView,
        layout: {GlimeshWeb.Layouts, :app}

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def surface_live_component do
    quote do
      use Surface.LiveComponent

      import Glimesh.Formatters

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      # import Phoenix.View
      import GlimeshWeb.CoreComponents
      import GlimeshWeb.ErrorHelpers

      import GlimeshWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      alias GlimeshWeb.Router.Helpers, as: Routes
      alias GlimeshWeb.Components.Navbar, as: Navbar

      alias GlimeshWeb.Components.Icons
      alias GlimeshWeb.Components.Title

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: GlimeshWeb.Endpoint,
        router: GlimeshWeb.Router,
        statics: GlimeshWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
