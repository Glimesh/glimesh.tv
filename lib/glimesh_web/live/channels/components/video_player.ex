defmodule GlimeshWeb.Channels.Components.VideoPlayer do
  use GlimeshWeb, :surface_live_component

  alias Glimesh.Streams.Channel
  alias GlimeshWeb.Router.Helpers, as: Routes

  prop channel, :struct
  prop country, :string
  prop muted, :boolean, default: false

  data status, :string, default: ""
  data janus_url, :string, default: nil

  def render(%{channel: %Channel{}} = assigns) do
    ~F"""
    <div id="video-container" class="embed-responsive embed-responsive-16by9">
      <video
        id="video-player"
        class="embed-responsive-item"
        :hook="VideoPlayer"
        controls
        playsinline
        poster={get_stream_thumbnail(@channel)}
        muted={@muted}
        data-janus-url={@janus_url}
        data-channel-id={@channel.id}
        data-status={@status}
      >
      </video>
      <div id="video-loading-container" class="">
        <div class="lds-ring">
          <div />
          <div />
          <div />
          <div />
        </div>
      </div>
    </div>
    """
  end

  def play(player_id, country) do
    case Glimesh.Janus.get_closest_edge_location(country) do
      %Glimesh.Janus.EdgeRoute{id: janus_edge_id, url: janus_url, hostname: janus_hostname} ->
        send_update(__MODULE__, id: player_id, status: "ready", janus_url: janus_url)

      _ ->
        # In the event we can't find an edge, something is real wrong
        send_update(__MODULE__,
          id: player_id,
          loaded: true,
          player_error: "Unable to find edge video location, we'll be back soon!"
        )
    end
  end

  defp get_stream_thumbnail(%Channel{} = channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
  end
end
