defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile
  alias Glimesh.Presence
  alias Glimesh.Streams
  alias Glimesh.ChannelLookups

  def mount(%{"username" => streamer_username}, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Process.send(self(), :load_stream, [])

    case ChannelLookups.get_channel_for_username!(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        streamer = Accounts.get_user!(channel.streamer_id)

        avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

        {:ok,
         socket
         |> put_page_title(channel.title)
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:streamer, channel.user)
         |> assign(:channel, channel)
         |> assign(:backend, channel.backend)
         |> assign(:janus_hostname, "Loading...")
         |> assign(:channel_id, channel.id)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end

  def handle_info(:load_stream, socket) do
    # Keep track of viewers using their socket ID, but later we'll keep track of chatters by their user
    Presence.track_presence(
      self(),
      Streams.get_subscribe_topic(:viewers, socket.assigns.channel_id),
      socket.id,
      %{}
    )

    janus_uri = random_janus_server()
    janus_hostname = hostname_from_url(janus_uri)

    {:noreply,
     socket
     |> push_event("load_video", %{
       janus_uri: janus_uri,
       channel_id: socket.assigns.channel_id
     })
     |> assign(:janus_uri, janus_uri)
     |> assign(:janus_hostname, janus_hostname)}
  end

  defp random_janus_server do
    [
      "https://do-nyc3-edge1.kjfk.live.glimesh.tv/janus",
      "https://do-nyc3-edge2.kjfk.live.glimesh.tv/janus",
      "https://do-nyc3-edge3.kjfk.live.glimesh.tv/janus"
    ]
    |> Enum.random()
  end

  defp hostname_from_url(url) do
    %URI{host: host} = URI.parse(url)
    host |> String.split(".") |> hd()
  end
end
