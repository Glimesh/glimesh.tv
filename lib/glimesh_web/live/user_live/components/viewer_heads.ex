defmodule GlimeshWeb.UserLive.Components.ViewerHeads do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence

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
    chatters_topic = "chatters:#{streamer}"

    chatters = Presence.list_presences(chatters_topic) |> Enum.take(24)
    GlimeshWeb.Endpoint.subscribe(chatters_topic)

    {:ok, assign(socket, :chatters, chatters)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", topic: "chatters:" <> streamer}, socket) do
    chatters =
      Presence.list_presences("chatters:#{streamer}")
      |> Enum.sort(fn x, y -> x.size > y.size end)
      |> Enum.take(24)

    # This may be expensive?
    {:noreply, socket |> assign(:chatters, chatters)}
  end
end
