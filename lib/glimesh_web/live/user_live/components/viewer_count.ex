defmodule GlimeshWeb.UserLive.Components.ViewerCount do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
      <button class="btn btn-danger"><%= dgettext("streams", " %{count} Viewers", count: @viewer_count) %></button>
    """
  end

  @impl true
  def mount(_params, %{"streamer_id" => streamer_id}, socket) do
    {:ok, topic} = Streams.subscribe_to(:viewers, streamer_id)

    viewer_count = Presence.list_presences(topic) |> Enum.count()

    {:ok, assign(socket, :viewer_count, viewer_count)}
  end

  @impl true
  def handle_info(
        %{
          event: "presence_diff",
          topic: "streams:viewers:" <> _streamer,
          payload: %{joins: joins, leaves: leaves}
        },
        %{assigns: %{viewer_count: count}} = socket
      ) do
    viewer_count = count + map_size(joins) - map_size(leaves)

    {:noreply, socket |> assign(:viewer_count, viewer_count)}
  end
end
