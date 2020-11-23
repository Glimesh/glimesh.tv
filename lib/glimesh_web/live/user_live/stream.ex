defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(%{"username" => streamer_username}, session, socket) do
    case Streams.get_channel_for_username!(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        # Keep track of viewers using their socket ID, but later we'll keep track of chatters by their user
        Presence.track_presence(
          self(),
          Streams.get_subscribe_topic(:viewers, channel.id),
          socket.id,
          %{}
        )

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        # If the viewer is logged in set their locale, otherwise it defaults to English
        if session["locale"], do: Gettext.put_locale(session["locale"])

        {:ok,
         socket
         |> assign(:page_title, channel.title)
         |> assign(:streamer, channel.user)
         |> assign(:channel, channel)
         |> assign(:backend, channel.backend)
         |> assign(:janus_uri, "https://01-nyc3.ftl.live.glimesh.tv/janus")
         |> assign(:channel_id, channel.id)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end
end
