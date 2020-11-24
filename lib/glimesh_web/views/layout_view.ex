defmodule GlimeshWeb.LayoutView do
  use GlimeshWeb, :view

  def html_root_tags(conn) do
    []
    |> dark_mode_attribute(conn)
    |> lang_attribute(conn)
  end

  defp dark_mode_attribute(attributes, conn) do
    if Plug.Conn.get_session(conn, :light_mode) do
      ["data-theme=\"light\"" | attributes]
    else
      attributes
    end
  end

  defp lang_attribute(attributes, conn) do
    case Plug.Conn.get_session(conn, :locale) do
      nil ->
        ["lang=\"en\"" | attributes]

      locale ->
        ["lang=\"#{locale}\"" | attributes]
    end
  end

  def active_user_profile_path(conn) do
    truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :profile])
  end

  def active_user_stream_path(conn) do
    truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :stream])
  end

  def active_user_payments_path(conn) do
    truthy_active(controller_action(conn) == [GlimeshWeb.UserPaymentsController, :index])
  end

  def active_user_settings_path(conn) do
    truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :settings])
  end

  def active_user_security_path(conn) do
    truthy_active(controller_action(conn) == [GlimeshWeb.UserSecurityController, :index])
  end

  def active_user_applications_path(conn) do
    truthy_active(hd(controller_action(conn)) == GlimeshWeb.UserApplicationsController)
  end

  def active_user_authorizations_path(conn) do
    truthy_active(
      hd(controller_action(conn)) == GlimeshWeb.Oauth2Provider.AuthorizedApplicationController
    )
  end

  def active_channel_moderator_path(conn) do
    truthy_active(hd(controller_action(conn)) == GlimeshWeb.ChannelModeratorController)
  end

  defp controller_action(conn) do
    [controller_module(conn), action_name(conn)]
  end

  defp truthy_active(stmt) do
    if stmt do
      "active"
    else
      ""
    end
  end
end
