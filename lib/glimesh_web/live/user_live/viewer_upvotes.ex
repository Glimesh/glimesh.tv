defmodule GlimeshWeb.UserLive.ViewerUpvotes do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence

  @impl true
  def render(assigns) do
    ~L"""
      <button class="btn btn-outline-primary" phx-click="upvote"><i class="fas fa-arrow-alt-circle-up"></i> <span><%= @upvotes %></span></button>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = _, socket) do
    chatters_topic = "chatters:#{streamer}"

    chatters = Presence.list_presences(chatters_topic)
    GlimeshWeb.Endpoint.subscribe(chatters_topic)

    {:ok,
     socket
     |> assign(:chatters, chatters)
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:upvotes, 0)}
  end

  @impl true
  def handle_event("upvote", _, socket) do
    Presence.update_presence(
      self(),
      "chatters:#{socket.assigns.streamer}",
      socket.assigns.user.id,
      fn x -> %{x | size: x.size + 5} end
    )

    {:noreply, socket |> assign(:upvotes, socket.assigns.upvotes + 1)}
  end
end
