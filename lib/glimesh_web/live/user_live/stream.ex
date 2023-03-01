defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.{ChannelHostsLookups, ChannelLookups}
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(%{"username" => streamer_username} = params, session, socket) do
    case ChannelLookups.get_channel_for_username(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        streamer = Accounts.get_user!(channel.streamer_id)

        {:ok,
         %{
           :redirect_to_hosted_target => redirect_to_hosted_target,
           :hosting_channel => hosting_channel
         }} = get_hosting_data(params, channel, maybe_user, streamer, session["user_agent"])

        if redirect_to_hosted_target do
          {:ok,
           socket
           |> redirect(
             to:
               "/#{hosting_channel.target.user.username}/?host=#{hosting_channel.host.user.username}"
           )}
        else
          if connected?(socket) do
            # Wait until the socket connection is ready to load the stream
            if Streams.is_live?(channel) do
              Process.send(self(), :load_stream, [])
            end

            Streams.subscribe_to(:channel, channel.id)
          end

          avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

          has_some_support_option =
            length(Glimesh.Streams.list_support_tabs(channel.user, channel)) > 0

          {:ok,
           socket
           |> put_page_title(channel.title)
           |> assign(:show_debug, false)
           |> assign(:show_support_modal, socket.assigns.live_action == :support)
           |> assign(:support_modal_tab, Map.get(params, "tab"))
           |> assign(:stripe_session_id, Map.get(params, "stripe_session_id"))
           |> assign(:unique_user, Map.get(session, "unique_user"))
           |> assign(:country, Map.get(session, "country"))
           |> assign(:prompt_mature, Streams.prompt_mature_content(channel, maybe_user))
           |> assign(:streamer, channel.user)
           |> assign(:can_receive_payments, Accounts.can_receive_payments?(channel.user))
           |> assign(:has_some_support_option, has_some_support_option)
           |> assign(:channel, channel)
           |> assign(:hosting_channel, hosting_channel)
           |> assign(:stream, channel.stream)
           |> assign(:channel_poster, get_stream_thumbnail(channel))
           |> assign(:custom_meta, meta_tags(channel, avatar_url))
           |> assign(:janus_url, "Pending...")
           |> assign(:janus_hostname, "Pending...")
           |> assign(:lost_packets, 0)
           |> assign(:stream_metadata, get_last_stream_metadata(channel.stream))
           |> assign(:player_error, nil)
           |> assign(:user, maybe_user)
           |> assign(:ultrawide, false)
           |> assign(:webrtc_error, false)}
        end

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end

  defp get_hosting_data(params, channel, maybe_user, streamer, user_agent) do
    is_live = Streams.is_live?(channel)
    is_twitterbot = user_agent =~ "Twitterbot"

    hosting_channel =
      cond do
        params["host"] ->
          ChannelHostsLookups.get_targets_host_info(params["host"], channel)

        is_live == false ->
          ChannelHostsLookups.get_current_hosting_target(channel)

        true ->
          nil
      end

    # this channel is hosting another
    not_bot_and_not_live = is_twitterbot == false and is_live == false

    host_valid = hosting_channel != nil and check_host_params(params)

    not_streamer = maybe_user == nil or maybe_user.id != streamer.id

    {:ok,
     %{
       is_live: is_live,
       hosting_channel: hosting_channel,
       redirect_to_hosted_target: not_bot_and_not_live and host_valid and not_streamer
     }}
  end

  defp check_host_params(params) do
    params["host"] == nil and params["follow_host"] != "false"
  end

  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket |> assign(:show_support_modal, socket.assigns.live_action == :support)}
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
    if socket.assigns.status == "offline" and channel.status == "live" and
         socket.assigns.prompt_mature == false do
      Process.send(self(), :load_stream, [])
    end

    {:noreply, socket |> assign(:stream, channel.stream)}
  end

  def handle_event("show_mature", _value, socket) do
    Process.send(self(), :load_stream, [])

    {:noreply, assign(socket, :prompt_mature, false)}
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

  def handle_event("lost_packets", %{"uplink" => _uplink, "lostPackets" => lost_packets}, socket)
      when is_integer(lost_packets) do
    message =
      if lost_packets > 6,
        do:
          gettext(
            "We're detecting some networking problems between you and the streamer. You may experience video drops, jitter, or other issues! If this continues, the streamer is recommended to submit a ticket in #streaming-help in our Discord."
          ),
        else: nil

    {:noreply,
     socket
     |> update(:lost_packets, &(&1 + lost_packets))
     |> assign(:player_error, message)}
  end

  def handle_event("lost_packets", _, socket) do
    {:noreply, socket}
  end

  def handle_event("webrtc_error", message, socket) do
    {:noreply, socket |> assign(:webrtc_error, message)}
  end

  def handle_event("ultrawide", %{"enabled" => enabled}, socket) do
    {:noreply, socket |> assign(:ultrawide, enabled)}
  end

  defp get_stream_thumbnail(channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
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

  defp meta_tags(%Streams.Channel{status: "live"} = channel, _) do
    %{
      title: channel.title,
      description: "#{channel.user.displayname} is streaming live on Glimesh.tv!",
      card_type: "summary_large_image",
      image_url: get_stream_thumbnail(channel)
    }
  end

  defp meta_tags(%Streams.Channel{} = channel, avatar_url) do
    %{
      title: "#{channel.user.displayname}'s Glimesh Channel",
      description:
        "#{channel.user.displayname}'s channel on Glimesh, the next-gen live streaming platform.",
      image_url: avatar_url
    }
  end
end
