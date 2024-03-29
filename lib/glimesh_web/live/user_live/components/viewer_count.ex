defmodule GlimeshWeb.UserLive.Components.ViewerCount do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~H"""
    <button
      class="btn btn-danger btn-responsive"
      data-toggle="tooltip"
      title="Viewers"
      phx-click="toggle"
    >
      <%= if @visible do %>
        <span class="d-none d-lg-block">
          <%= gettext("%{count} Viewers", count: @viewer_count) %>
        </span>
        <span class="d-lg-none">
          <%= gettext("%{count} ", count: @viewer_count) %><i class="far fa-eye"></i>
        </span>
      <% else %>
        <i class="far fa-eye-slash"></i>
      <% end %>
    </button>
    """
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    {:ok, topic} = Streams.subscribe_to(:viewers, channel_id)

    viewer_count = Presence.list_presences(topic) |> Enum.count()

    {:ok, socket |> assign(:visible, true) |> assign(:viewer_count, viewer_count)}
  end

  @impl true
  def handle_info(
        %{
          event: "presence_diff",
          topic: "streams:viewers:" <> _streamer = topic
        },
        socket
      ) do
    {:noreply, socket |> assign(:viewer_count, Presence.list_presences(topic) |> Enum.count())}
  end

  @impl true
  def handle_event("toggle", %{}, socket) do
    {:noreply, assign(socket, :visible, !socket.assigns.visible)}
  end
end
