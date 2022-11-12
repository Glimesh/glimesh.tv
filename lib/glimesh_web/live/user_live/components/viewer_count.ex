defmodule GlimeshWeb.UserLive.Components.ViewerCount do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~H"""
    <%= case @viewer_count_state do %>
      <% value when value in [:visible, :maximize] -> %>
        <button
          class="btn btn-danger btn-responsive"
          data-toggle="tooltip"
          title="Viewers"
          phx-click="toggle"
        >
          <span class="d-none d-lg-block">
            <%= gettext("%{count} Viewers", count: @viewer_count) %>
          </span>
          <span class="d-lg-none">
            <%= gettext("%{count} ", count: @viewer_count) %><i class="far fa-eye"></i>
          </span>
        </button>
      <% :minimize -> %>
        <button
          class="btn btn-danger btn-responsive"
          data-toggle="tooltip"
          title="Viewers"
          phx-click="toggle"
        >
          <i class="far fa-eye-slash"></i>
        </button>
      <% _ -> %>
    <% end %>
    """
  end

  @impl true
  def mount(
        _params,
        %{"channel_id" => channel_id, "viewer_count_state" => viewer_count_state} = session,
        socket
      ) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    {:ok, topic} = Streams.subscribe_to(:viewers, channel_id)

    viewer_count = Presence.list_presences(topic) |> Enum.count()

    {:ok,
     socket
     |> assign(:viewer_count_state, viewer_count_state)
     |> assign(:viewer_count, viewer_count)}
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
    new_state =
      case socket.assigns.viewer_count_state do
        :visible ->
          :minimize

        :minimize ->
          :maximize

        :maximize ->
          :minimize

        _ ->
          socket.assigns.viewer_count_state
      end

    {:noreply, assign(socket, :viewer_count_state, new_state)}
  end
end
