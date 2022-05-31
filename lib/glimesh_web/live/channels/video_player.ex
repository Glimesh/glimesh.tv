defmodule GlimeshWeb.Channels.VideoPlayer do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="video-container" class="embed-responsive embed-responsive-16by9">
      <video
        id="video-player"
        class="embed-responsive-item"
        phx-hook="FtlVideo"
        controls
        playsinline
        poster={@channel_poster}
        data-muted={@muted}
      >
      </video>
      <div id="video-loading-container" class="">
        <div class="lds-ring">
          <div></div>
          <div></div>
          <div></div>
          <div></div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    if connected?(socket) do
      # Wait until the socket connection is ready to load the stream
      Process.send(self(), :load_stream, [])
    end

    {:ok,
     assign(socket,
       channel_id: session["channel_id"],
       muted: Map.get(session, "muted", false),
       unique_user: session["unique_user"],
       channel_poster: session["channel_poster"],
       country: session["country"]
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(:load_stream, socket) do
    case Glimesh.Janus.get_closest_edge_location(socket.assigns.country) do
      %Glimesh.Janus.EdgeRoute{id: janus_edge_id, url: janus_url, hostname: janus_hostname} ->
        Presence.track_presence(
          self(),
          Streams.get_subscribe_topic(:viewers, socket.assigns.channel_id),
          socket.assigns.unique_user,
          %{
            janus_edge_id: janus_edge_id
          }
        )

        Process.send(
          socket.parent_pid,
          {:debug, :janus_info,
           %{
             janus_url: janus_url,
             janus_hostname: janus_hostname
           }},
          []
        )

        Process.send(socket.parent_pid, {:debug, :remove_packet_warning, true}, [])

        {:noreply,
         socket
         |> push_event("load_video", %{
           janus_url: janus_url,
           channel_id: socket.assigns.channel_id
         })
         |> assign(:janus_url, janus_url)
         |> assign(:janus_hostname, janus_hostname)}

      _ ->
        # In the event we can't find an edge, something is real wrong
        {:noreply,
         socket
         |> assign(:player_error, "Unable to find edge video location, we'll be back soon!")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("lost_packets", %{"uplink" => _uplink, "lostPackets" => lost_packets}, socket)
      when is_integer(lost_packets) do
    # Send packet loss up the chain so other components can handle it
    Process.send(socket.parent_pid, {:debug, :packet_loss, lost_packets}, [])

    {:noreply, socket}
  end

  def handle_event("ultrawide", _, socket) do
    {:noreply, socket}
  end

  def handle_event("lost_packets", _, socket) do
    {:noreply, socket}
  end
end
