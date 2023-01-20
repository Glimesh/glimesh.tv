defmodule GlimeshWeb.LayoutView do
  # use GlimeshWeb, :view

  # def html_root_tags(conn) do
  #   []
  #   |> site_theme_attribute(conn)
  #   |> lang_attribute(conn)
  #   |> Enum.join(" ")
  # end

  # defp site_theme_attribute(attributes, conn) do
  #   theme = site_theme(conn)
  #   ["data-theme=\"#{theme}\"" | attributes]
  # end

  # defp lang_attribute(attributes, conn) do
  #   locale = site_locale(conn)
  #   ["lang=\"#{locale}\"" | attributes]
  # end

  # def site_theme_label(conn) do
  #   case site_theme(conn) do
  #     "dark" -> "🌘"
  #     "light" -> "☀️"
  #   end
  # end

  # def site_locale_label(conn) do
  #   site_locale(conn)
  # end

  # def site_locale(conn) do
  #   case Plug.Conn.get_session(conn, :locale) do
  #     nil ->
  #       "en"

  #     locale ->
  #       locale
  #   end
  # end

  # def site_theme(conn) do
  #   case Plug.Conn.get_session(conn, :site_theme) do
  #     nil ->
  #       "dark"

  #     theme ->
  #       theme
  #   end
  # end

  # # About Paths
  # def active_about_path(conn, action) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.AboutController, action])
  # end

  # # User Settings Paths

  # def active_user_profile_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :profile])
  # end

  # def active_user_stream_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :stream])
  # end

  # def active_user_emotes_path(conn) do
  #   truthy_active(
  #     controller_action(conn) == [GlimeshWeb.UserSettingsController, :emotes] or
  #       controller_action(conn) == [GlimeshWeb.UserSettingsController, :upload_emotes]
  #   )
  # end

  # def active_user_hosting_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :hosting])
  # end

  # def active_channel_addons_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :addons])
  # end

  # def active_user_payments_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserPaymentsController, :index])
  # end

  # def active_user_settings_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :preference])
  # end

  # def active_user_notifications_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSettingsController, :notifications])
  # end

  # def active_channel_statistics_path(conn) do
  #   truthy_active(
  #     controller_action(conn) == [GlimeshWeb.UserSettingsController, :channel_statistics]
  #   )
  # end

  # def active_user_security_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.UserSecurityController, :index])
  # end

  # def active_user_applications_path(conn) do
  #   truthy_active(hd(controller_action(conn)) == GlimeshWeb.UserApplicationsController)
  # end

  # def active_user_authorizations_path(conn) do
  #   truthy_active(
  #     hd(controller_action(conn)) == GlimeshWeb.Oauth2Provider.AuthorizedApplicationController
  #   )
  # end

  # def active_channel_moderator_path(conn) do
  #   truthy_active(hd(controller_action(conn)) == GlimeshWeb.ChannelModeratorController)
  # end

  # # GCT Path checks
  # def active_gct_dashboard_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.GctController, :index])
  # end

  # def active_gct_audit_log_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.GctController, :audit_log])
  # end

  # def active_gct_global_emotes_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.GctController, :global_emotes])
  # end

  # def active_gct_review_emotes_path(conn) do
  #   truthy_active(controller_action(conn) == [GlimeshWeb.GctController, :review_emotes])
  # end

  # defp controller_action(conn) do
  #   [controller_module(conn), action_name(conn)]
  # end

  # defp truthy_active(stmt) do
  #   if stmt do
  #     "active"
  #   else
  #     ""
  #   end
  # end

  # def count_live_following_channels(%{assigns: %{current_user: user}}) do
  #   count = length(Glimesh.ChannelLookups.list_live_followed_channels(user))

  #   if count > 0 do
  #     count
  #   else
  #     nil
  #   end
  # end

  # def count_live_following_channels(_) do
  #   nil
  # end

  # def count_live_hosted_channels(%{assigns: %{current_user: user}}) do
  #   count = Glimesh.ChannelLookups.count_live_followed_channels_that_are_hosting(user)

  #   if count > 0 do
  #     count
  #   else
  #     nil
  #   end
  # end

  # def count_live_hosted_channels(_) do
  #   nil
  # end
end
