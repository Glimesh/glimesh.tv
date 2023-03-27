defmodule GlimeshWeb.ChannelSettings.ModsLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/settings/channel/mods"}>
      <:title><%= gettext("Moderators") %></:title>

      <:nav>
        <Settings.tab_nav>
          <:item to={~p"/users/settings/channel/mods"} active={@live_action == :settings}>
            <%= gettext("Channel Moderators") %>
          </:item>
          <:item to={~p"/users/settings/hosting/channels"} active={@live_action == :channels}>
            <%= gettext("Bans & Timeouts") %>
          </:item>
          <:item to={~p"/users/settings/hosting/channels"} active={@live_action == :channels}>
            <%= gettext("Moderation Log") %>
          </:item>
        </Settings.tab_nav>
      </:nav>
    </Settings.page>
    """
  end

  def mount(_, _, socket) do
    {:ok, socket |> put_page_title(gettext("Moderators"))}
  end
end
