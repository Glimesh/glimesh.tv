defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile
  alias Glimesh.ChannelLookups
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(%{"username" => streamer_username}, session, socket) do
    case ChannelLookups.get_channel_for_username(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        if connected?(socket) do
          # Wait until the socket connection is ready to load the stream
          Process.send(self(), :load_stream, [])
          Streams.subscribe_to(:channel, channel.id)
        end

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        streamer = Accounts.get_user!(channel.streamer_id)

        avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

        {:ok,
         socket
         |> put_page_title(channel.title)
         |> assign(:show_debug, false)
         |> assign(:unique_user, Map.get(session, "unique_user"))
         |> assign(:country, Map.get(session, "country"))
         |> assign(:prompt_mature, Streams.prompt_mature_content(channel, maybe_user))
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:streamer, channel.user)
         |> assign(:can_receive_payments, Accounts.can_receive_payments?(channel.user))
         |> assign(:channel, channel)
         |> assign(:stream, channel.stream)
         |> assign(:channel_poster, get_stream_thumbnail(channel))
         |> assign(:janus_url, "Pending...")
         |> assign(:janus_hostname, "Pending...")
         |> assign(:lost_packets, 0)
         |> assign(:stream_metadata, get_last_stream_metadata(channel))
         |> assign(:player_error, nil)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
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

        Process.send(self(), :update_stream, [])

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

  def handle_info(:update_stream, socket) do
    Process.send_after(self(), :update_stream, 30_000)

    {:noreply,
     socket
     # Reset player error every 30 seconds to clear packet loss message
     |> assign(:player_error, nil)
     |> assign(:stream_metadata, get_last_stream_metadata(socket.assigns.stream))}
  end

  def handle_info({:channel, channel}, socket) do
    {:noreply, socket |> assign(:stream, channel.stream)}
  end

  def handle_event("show_mature", _value, socket) do
    Process.send(self(), :load_stream, [])

    {:noreply, assign(socket, :prompt_mature, false)}
  end

  def handle_event("toggle_debug", _value, socket) do
    {:noreply, assign(socket, :show_debug, !socket.assigns.show_debug)}
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

  defp get_stream_thumbnail(channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
  end

  defp get_last_stream_metadata(stream) do
    case stream do
      %Glimesh.Streams.Stream{} = stream ->
        # Sometimes the stream can be live without metadata, usually happens within the
        # first couple of seconds of loading the page
        case Glimesh.Streams.get_last_stream_metadata(stream) do
          %Glimesh.Streams.StreamMetadata{} = metadata ->
            metadata

          _ ->
            %Glimesh.Streams.StreamMetadata{}
        end

      _ ->
        %Glimesh.Streams.StreamMetadata{}
    end
  end
end
