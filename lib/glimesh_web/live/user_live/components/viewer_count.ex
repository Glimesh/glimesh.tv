defmodule GlimeshWeb.UserLive.Components.ViewerCount do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
      <button class="btn btn-danger btn-responsive" data-toggle="tooltip" title="Viewers" phx-click="toggle">
      <%= if @visible do %>
      <span class="v_txt"><%= gettext("%{count} Viewers", count: @viewer_count) %></span><span class="v_ico"><%= gettext("%{count} ", count: @viewer_count) %><i class="far fa-eye"></i></span>
      <% else %>
      <i class="far fa-eye-slash"></i>
      <% end %>
      </button>
    """
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id}, socket) do
    {:ok, topic} = Streams.subscribe_to(:viewers, channel_id)

    viewer_count = Presence.list_presences(topic) |> Enum.count()

    {:ok, socket |> assign(:visible, true) |> assign(:viewer_count, viewer_count)}
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

  @impl true
  def handle_event("toggle", %{}, socket) do
    {:noreply, assign(socket, :visible, !socket.assigns.visible)}
  end
end
