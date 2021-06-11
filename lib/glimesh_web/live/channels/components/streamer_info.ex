defmodule GlimeshWeb.Channels.StreamerInfoComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use GlimeshWeb, :live_component

  def render(assigns) do
    ~L"""
    <div id="streamer-avatar">
        <a href="<%= Routes.user_profile_path(@socket, :index, @streamer.username) %>">
            <img src="<%= @avatar %>" alt="<%= @streamer.displayname %>" width="48" height="48" class="img-avatar mr-2 float-left <%= if @can_receive_payments, do: "img-verified-streamer", else: "" %>">
        </a>
    </div>
    <a title="<%= gettext("View Profile") %>" class="<%= @username_color %>" href="<%= Routes.user_profile_path(@socket, :index, @streamer.username) %>">
        <h3 class="mb-0"><%= @streamer.displayname %></h3>
    </a>

    <span class="badge badge-pill badge-info ml-2"><%= @channel.language %></span>
    <%= if @channel.mature_content do %>
    <span class="badge badge-pill badge-warning ml-2"><%= gettext("Mature") %></span>
    <% end %>

    <%= live_component(@socket, GlimeshWeb.UserLive.Components.SocialButtons, container: {:ul, class: "list-inline ml-2 mb-0"}, streamer: @streamer) %>
    """
  end

  def update(assigns, socket) do
    {:ok,
     assign(
       socket,
       Map.merge(assigns, %{
         avatar: Glimesh.Accounts.Profile.get_avatar_url(assigns.streamer),
         can_receive_payments: Glimesh.Accounts.can_receive_payments?(assigns.streamer),
         username_color: Glimesh.Chat.Effects.get_username_color(assigns.streamer)
       })
     )}
  end
end
