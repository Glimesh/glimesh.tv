defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.{ChannelHostsLookups, ChannelLookups}
  alias Glimesh.Presence
  alias Glimesh.Streams

  alias GlimeshWeb.Channels.Components.ChannelTitle
  alias GlimeshWeb.Channels.Components.ReportButton
  alias GlimeshWeb.Components.UserEffects

  alias GlimeshWeb.Channels.Components.VideoPlayer
  alias GlimeshWeb.UserLive.Components.ViewerCount

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
            # Setup our subscriptions
            Process.send(self(), :load_stream, [])

            Streams.subscribe_to(:channel, channel.id)
            Streams.subscribe_to(:chat, channel.id)
            {:ok, viewers_topic} = Streams.subscribe_to(:viewers, channel.id)

            send_update(ViewerCount,
              id: "viewer-count",
              viewer_count: Presence.list_presences(viewers_topic) |> Enum.count()
            )
          end

          avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

          has_some_support_option =
            length(Glimesh.Streams.list_support_tabs(channel.user, channel)) > 0

          initial_chat_messages = list_chat_messages(channel)

          {:ok,
           socket
           |> put_page_title(channel.title)
           |> assign(:unique_user, Map.get(session, "unique_user"))
           |> assign(:country, Map.get(session, "country"))
           |> assign(:prompt_mature, Streams.prompt_mature_content(channel, maybe_user))
           |> assign(:streamer, channel.user)
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
           # Support Modal
           |> assign(:show_support_modal, socket.assigns.live_action == :support)
           |> assign(:support_modal_tab, Map.get(params, "tab"))
           |> assign(:stripe_session_id, Map.get(params, "stripe_session_id")),
           temporary_assigns: [chat_messages: initial_chat_messages]}
        end

      nil ->
        dbg(streamer_username)
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end

  defp list_chat_messages(
         %Glimesh.Streams.Channel{show_recent_chat_messages_only: true} = channel
       ) do
    Glimesh.Chat.list_recent_chat_messages(channel)
  end

  defp list_chat_messages(channel) do
    Glimesh.Chat.list_chat_messages(channel)
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

  # Stream Event Handler
  @impl true
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

        # Tell the video player to play
        send_update(VideoPlayer, id: "video-player", janus_url: janus_url, status: "ready")

        {:noreply, socket}

      _ ->
        # In the event we can't find an edge, something is real wrong
        {:noreply,
         socket
         |> assign(:player_error, "Unable to find edge video location, we'll be back soon!")}
    end
  end

  def handle_info({:channel, channel}, socket) do
    {:noreply, socket |> assign(:stream, channel.stream)}
  end

  # Viewer List Event Handler
  def handle_info(
        %{
          event: "presence_diff",
          topic: "streams:viewers:" <> _streamer = topic
        },
        socket
      ) do
    send_update(ViewerCount,
      id: "viewer-count",
      viewer_count: Presence.list_presences(topic) |> Enum.count()
    )

    {:noreply, socket}
  end

  # Chat Event Handler
  @impl true
  def handle_info({:chat_message, message}, socket) do
    {:noreply,
     socket
     |> push_event("new_chat_message", %{
       message_id: message.id
     })
     |> update(:chat_messages, fn messages -> [message | messages] end)}
  end

  @impl true
  def handle_info({:user_timedout, bad_user}, socket) do
    {:noreply, push_event(socket, "remove_timed_out_user_messages", %{bad_user_id: bad_user.id})}
  end

  @impl true
  def handle_info({:message_deleted, message_id}, socket) do
    {:noreply, push_event(socket, "remove_deleted_message", %{message_id: message_id})}
  end

  def handle_event("show_mature", _value, socket) do
    Process.send(self(), :load_stream, [])

    {:noreply, assign(socket, :prompt_mature, false)}
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
