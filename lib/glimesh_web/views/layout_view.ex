defmodule GlimeshWeb.LayoutView do
  use GlimeshWeb, :view

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
