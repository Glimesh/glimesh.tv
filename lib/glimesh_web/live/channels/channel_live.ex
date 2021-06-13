defmodule GlimeshWeb.Channels.ChannelLive do
  use GlimeshWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    channel = Glimesh.ChannelLookups.get_channel_for_username("clone1018")
    maybe_user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     assign(socket,
       channel: channel,
       streamer: channel.user,
       user: maybe_user,
       prompt_mature: false,
       player_error: nil,
       show_debug: false,
       channel_info_footer_params: footer_params(channel)
     )}
  end

  @impl Phoenix.LiveView
  def handle_info({:debug_pid, new_pid}, socket) do
    {:noreply, assign(socket, debug_pid: new_pid)}
  end

  # def handle_info({:debug, _event, _data} = event, socket) do
  #   if socket.assigns.debug_pid do
  #     # We may not always have a debug pid, so we can ignore it sometimes.
  #     Process.send(socket.assigns.debug_pid, event, [])
  #   end

  #   {:noreply, socket}
  # end

  defp footer_params(%Glimesh.Streams.Channel{user: streamer} = channel) do
    %{
      "streamer_id" => streamer.id,
      "streamer_username" => streamer.username,
      "streamer_avatar" => Glimesh.Avatar.url({streamer.avatar, streamer}, :original),
      "streamer_displayname" => streamer.displayname,
      "streamer_can_receive_payments" => Glimesh.Accounts.can_receive_payments?(streamer),
      "streamer_color" => Glimesh.Chat.Effects.get_username_color(streamer),
      "channel_language" => channel.language,
      "channel_mature" => channel.mature_content
    }
  end
end
