defmodule GlimeshWeb.GctLive.Components.ChannelButtonArray do
  use GlimeshWeb, :live_view

  alias Glimesh.CommunityTeam

  @impl true
  def render(assigns) do
    ~L"""
    <%= live_redirect gettext("Edit Channel"), class: (if @can_edit_channel, do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_channel, @channel.id) %>
    """
  end

  @impl true
  def mount(_params, %{"admin" => admin, "channel" => channel}, socket) do
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
