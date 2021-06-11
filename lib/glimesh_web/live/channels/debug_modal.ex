defmodule GlimeshWeb.Channels.DebugModal do
  use GlimeshWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div>
      <a href="#" phx-click="toggle_debug" class="text-color-link <%= if @player_error, do: "text-warning", else: "" %>">
          <i class="fas fa-signal"></i>
          <span class="sr-only">Debug</span>
      </a>

    <%= if @show_debug do %>
      <div id="debugModal" class="live-modal" phx-capture-click="toggle_debug" phx-window-keydown="toggle_debug" phx-key="escape" phx-target="#debugModal" phx-page-loading>
          <div class="modal-dialog" role="document">
              <div class="modal-content">
                  <div class="modal-header">
                      <h5 class="modal-title"><%= gettext("Debug Information") %></h5>
                      <button type="button" class="close" phx-click="toggle_debug" aria-label="Close">
                          <span aria-hidden="true">&times;</span>
                      </button>
                  </div>

                  <div class="modal-body">
                      <%= if @player_error do %>
                      <div class="alert alert-warning" role="alert">
                          <%= @player_error %>
                      </div>
                      <% end %>
                      <pre class="px-2">
    == Janus Edge Information ==
    Edge Hostname: <%= @janus_hostname %>
    Edge URL: <%= @janus_url %>
    Reported Lost Packets: <%= @lost_packets %>
    <br>
    == Stream Metadata ==
    # Stream Metadata no longer auto reloads,
    # close & reopen modal to see newest data.
    ingest_server: <%= @stream_metadata.ingest_server %>
    ingest_viewers: <%= @stream_metadata.ingest_viewers %> // unused
    stream_time_seconds: <%= @stream_metadata.stream_time_seconds %>

    source_bitrate: <%= @stream_metadata.source_bitrate %>
    source_ping: <%= @stream_metadata.source_ping %> // unused

    recv_packets: <%= @stream_metadata.recv_packets %>
    lost_packets: <%= @stream_metadata.lost_packets %> // unused
    nack_packets: <%= @stream_metadata.nack_packets %> // unused

    vendor_name: <%= @stream_metadata.vendor_name %>
    vendor_version: <%= @stream_metadata.vendor_version %>

    audio_codec: <%= @stream_metadata.audio_codec %>
    video_codec: <%= @stream_metadata.video_codec %>
    video_height: <%= @stream_metadata.video_height %> // unused
    video_width: <%= @stream_metadata.video_width %> // unused

    inserted_at: <%= @stream_metadata.inserted_at %>
    updated_at: <%= @stream_metadata.updated_at %></pre>
                  </div>

              </div>
          </div>
      </div>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(socket.parent_pid, {:debug_pid, self()})
    end

    {:ok,
     assign(socket,
       player_error: nil,
       show_debug: false,
       lost_packets: 0
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_debug", _value, socket) do
    if socket.assigns.show_debug === false do
      # Opening the window
      {:noreply,
       socket
       |> assign(:stream_metadata, get_last_stream_metadata(socket.assigns.stream))
       |> assign(:show_debug, true)}
    else
      {:noreply, assign(socket, :show_debug, false)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:packet_loss, lost_packets}, socket) when is_integer(lost_packets) do
    message =
      if lost_packets > 6,
        do:
          gettext(
            "We're detecting some networking problems between you and the streamer. You may experience video drops, jitter, or other issues!"
          ),
        else: nil

    {:noreply,
     socket
     |> update(:lost_packets, &(&1 + lost_packets))
     |> assign(:player_error, message)}
  end

  def handle_info({:packet_loss, _}, socket) do
    {:noreply, socket}
  end

  defp get_last_stream_metadata(%Glimesh.Streams.Stream{} = stream) do
    case Glimesh.Streams.get_last_stream_metadata(stream) do
      %Glimesh.Streams.StreamMetadata{} = metadata -> metadata
      _ -> %Glimesh.Streams.StreamMetadata{stream: stream}
    end
  end

  defp get_last_stream_metadata(_) do
    %Glimesh.Streams.StreamMetadata{}
  end
end
