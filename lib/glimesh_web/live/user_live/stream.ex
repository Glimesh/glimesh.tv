defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile
  alias Glimesh.ChannelLookups
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(:not_mounted_at_router, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    if connected?(socket) do
      # Wait until the socket connection is ready to load the stream
      Process.send(self(), :load_stream, [])
    end

    case ChannelLookups.get_channel_for_username!(session["username"]) do
      %Glimesh.Streams.Channel{} = channel ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        streamer = Accounts.get_user!(channel.streamer_id)

        avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

        {:ok,
         socket
         |> put_page_title(channel.title)
         |> assign(:country, Map.get(session, "country"))
         |> assign(:prompt_mature, Streams.prompt_mature_content(channel, maybe_user))
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:streamer, channel.user)
         |> assign(:channel, channel)
         |> assign(:backend, channel.backend)
         |> assign(:janus_url, "Pending...")
         |> assign(:janus_hostname, "Pending...")
         |> assign(:player_error, nil)
         |> assign(:channel_id, channel.id)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/derp/profile")}
    end
  end

  def mount(%{"username" => streamer_username}, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    if connected?(socket) do
      # Wait until the socket connection is ready to load the stream
      Process.send(self(), :load_stream, [])
    end

    case ChannelLookups.get_channel_for_username!(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        streamer = Accounts.get_user!(channel.streamer_id)

        avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

        {:ok,
         socket
         |> put_page_title(channel.title)
         |> assign(:country, Map.get(session, "country"))
         |> assign(:prompt_mature, Streams.prompt_mature_content(channel, maybe_user))
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:streamer, channel.user)
         |> assign(:channel, channel)
         |> assign(:backend, channel.backend)
         |> assign(:janus_url, "Pending...")
         |> assign(:janus_hostname, "Pending...")
         |> assign(:player_error, nil)
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

    case Glimesh.Janus.get_closest_edge_location(socket.assigns.country) do
      %Glimesh.Janus.EdgeRoute{url: janus_url, hostname: janus_hostname} ->
        {:noreply,
         socket
         |> push_event("load_video", %{
           janus_url: janus_url,
           channel_id: socket.assigns.channel_id
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

  def handle_event("show_mature", _value, socket) do
    Process.send(self(), :load_stream, [])

    {:noreply, assign(socket, :prompt_mature, false)}
  end
end
