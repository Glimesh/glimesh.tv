defmodule GlimeshWeb.UserLive.Components.ViewerHeads do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
      <div class="avatar--group">
        <%= for chatter <- @chatters do %>
          <div id="chatter-<%= chatter.username %>" class="avatar">
              <img src="<%= chatter.avatar %>" class="rounded-circle bs-tooltip" data-toggle="tooltip" data-placement="bottom" data-original-title="<%= chatter.displayname %>" alt="<%= chatter.displayname %>" style="width: <%= chatter.size %>px; height: <%= chatter.size %>px;" />
          </div>
        <% end %>
        <%= if length(@chatters) > 23 do %>
        <div class="avatar">
          <span class="avatar-title rounded-circle">+<%= length(@chatters) - 23 %></span>
        </div>
        <% end %>
      </div>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer}, socket) do
    {:ok, chatters_topic} = Streams.get_subscribe_topic(:chatters, streamer.id)

    chatters = Presence.list_presences(chatters_topic) |> Enum.take(24)

    {:ok, assign(socket, :chatters, chatters)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", topic: topic}, socket) do
    chatters =
      Presence.list_presences(topic)
      |> Enum.sort(fn x, y -> x.size > y.size end)
      |> Enum.take(24)

    # This may be expensive?
    {:noreply, socket |> assign(:chatters, chatters)}
  end
end
