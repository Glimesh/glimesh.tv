defmodule GlimeshWeb.Channel.Components.VideoPlayer do
  use GlimeshWeb, :live_component

  alias Glimesh.Streams.Channel

  attr :channel_id, :integer, required: true
  attr :janus_url, :string, default: ""
  attr :poster, :string, default: "/images/stream-not-started.jpg"
  attr :muted, :boolean, default: false
  attr :status, :string, default: "loading"

  def render(assigns) do
    ~H"""
    <video
      id={@id}
      class="h-full mx-auto"
      phx-hook="FtlVideo"
      controls
      playsinline
      poster={@poster}
      muted={@muted}
      data-janus-url={@janus_url}
      data-channel-id={@channel_id}
      data-status={@status}
    >
    </video>
    """
  end
end
