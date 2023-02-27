defmodule GlimeshWeb.Channels.Components.VideoPlayer do
  use GlimeshWeb, :surface_live_component

  alias Glimesh.Streams.Channel

  prop(channel, :struct)
  prop(country, :string)
  prop(muted, :boolean, default: false)

  data(status, :string, default: "")

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
        data-channel-id={@channel.id}
        data-status={@status}
        data-rtrouter={Application.get_env(:glimesh, :rtrouter_url)}
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

  def play(player_id, _country) do
    send_update(__MODULE__, id: player_id, status: "ready")
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
