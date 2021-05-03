defmodule GlimeshWeb.StreamLive.Video do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile
  alias Glimesh.Avatar
  alias Glimesh.ChannelLookups
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    channel = ChannelLookups.get_channel!(session["channel_id"])
    streamer = Map.get(channel, :user, nil)
    stream = Map.get(channel, :stream, nil)

    if connected?(socket) do
      # Wait until the socket connection is ready to load the stream
      Process.send(self(), :load_stream, [])
    end

    avatar_url = Avatar.url({streamer.avatar, streamer}, :original)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:streamer, streamer)
     |> assign(:stream, stream)
     |> assign(:country, Map.get(session, "country"))
     |> assign(:channel_poster, get_stream_thumbnail(channel))
     |> assign(:janus_url, "Pending...")
     |> assign(:janus_hostname, "Pending...")
     |> assign(:lost_packets, 0)
     |> assign(:player_error, nil)
     |> assign(:show_debug, false)
     |> assign(:unique_user, Map.get(session, "unique_user"))
     |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
     |> assign(:stream_metadata, get_last_stream_metadata(stream))
     |> assign(:prompt_mature, Streams.prompt_mature_content(channel, user))
     |> assign(:can_receive_payments, Accounts.can_receive_payments?(channel.user))}
  end

  def handle_info(:load_stream, socket) do
    case Glimesh.Janus.get_closest_edge_location(socket.assigns.country) do
      %Glimesh.Janus.EdgeRoute{id: janus_edge_id, url: janus_url, hostname: janus_hostname} ->
        Presence.track_presence(
          self(),
          Streams.get_subscribe_topic(:viewers, socket.assigns.channel.id),
          socket.assigns.unique_user,
          %{
            janus_edge_id: janus_edge_id
          }
        )

        Process.send(self(), :remove_packet_warning, [])

        {:noreply,
         socket
         |> push_event("load_video", %{
           janus_url: janus_url,
           channel_id: socket.assigns.channel.id
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

  def handle_info(:remove_packet_warning, socket) do
    Process.send_after(self(), :remove_packet_warning, 15_000)

    {:noreply, socket |> assign(:player_error, nil)}
  end

  def handle_info({:channel, channel}, socket) do
    {:noreply, socket |> assign(:stream, channel.stream)}
  end

  def handle_event("show_mature", _value, socket) do
    Process.send(self(), :load_stream, [])

    {:noreply, assign(socket, :prompt_mature, false)}
  end

  def handle_event("lost_packets", %{"uplink" => _uplink, "lostPackets" => lostPackets}, socket) do
    message =
      if lostPackets > 6,
        do:
          gettext(
            "We're detecting some networking problems between you and the streamer. You may experience video drops, jitter, or other issues!"
          ),
        else: nil

    {:noreply,
     socket
     |> update(:lost_packets, &(&1 + lostPackets))
     |> assign(:player_error, message)}
  end

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

  defp get_stream_thumbnail(channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
  end

  defp get_last_stream_metadata(stream) do
    Glimesh.Streams.get_last_stream_metadata(stream)
  end
end
