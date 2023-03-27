defmodule GlimeshWeb.UserSettings.SecurityLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/settings/security"}>
      <:title><%= gettext("Security") %></:title>
    </Settings.page>
    """
  end

  def mount(_, _, socket) do
    {:ok, socket |> put_page_title(gettext("Security"))}
  end
end
