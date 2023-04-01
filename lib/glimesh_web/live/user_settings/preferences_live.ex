defmodule GlimeshWeb.UserSettings.PreferencesLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/settings/preferences"}>
      <:title><%= gettext("Preferences") %></:title>
    </Settings.page>
    """
  end

  def mount(_, _, socket) do
    {:ok, socket |> put_page_title(gettext("Preferences"))}
  end
end