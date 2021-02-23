defmodule GlimeshWeb.GctLive.Components.ChannelButtonArray do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~L"""
    <%= live_redirect gettext("Edit Channel"), class: (if @can_edit_channel, do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_channel, @channel.id) %>
    <%= live_redirect gettext("View Chat Log"), class: "btn btn-primary", to: Routes.gct_path(@socket, :channel_chat_log, @channel.id) %>
    <%= if @channel.status == "live" do %>
    <%= button gettext("Shutdown Broadcast"), class: (if @can_edit_channel, do: "btn btn-danger", else: "btn btn-danger disabled"), to: Routes.gct_path(@socket, :shutdown_channel, @channel.id), "data-confirm": "Are you sure you wish to shutdown the current stream, and remove this users ability to start a new stream?" %>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"admin" => admin, "channel" => channel}, socket) do
    Gettext.put_locale(Glimesh.Accounts.get_user_locale(admin))

    {:ok,
     socket
     |> assign(:admin, admin)
     |> assign(:channel, channel)
     |> assign(
       :can_edit_channel,
       Bodyguard.permit?(Glimesh.CommunityTeam, :edit_channel, admin, channel.user)
     )}
  end
end
