defmodule GlimeshWeb.UserLive.ViewerCount do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence

  @impl true
  def render(assigns) do
    ~L"""
      <span class="badge badge-danger"><%= @viewer_count %> Viewers</span>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer}, socket) do
    viewer_count_topic = "viewer_count:#{streamer}"

    viewer_count = Presence.list_presences(viewer_count_topic) |> Enum.count()
    GlimeshWeb.Endpoint.subscribe(viewer_count_topic)

    {:ok, assign(socket, :viewer_count, viewer_count)}
  end

  @impl true
  def handle_info(
        %{
          event: "presence_diff",
          topic: "viewer_count:" <> _streamer,
          payload: %{joins: joins, leaves: leaves}
        },
        %{assigns: %{viewer_count: count}} = socket
      ) do
    viewer_count = count + map_size(joins) - map_size(leaves)

    {:noreply, socket |> assign(:viewer_count, viewer_count)}
  end
end
