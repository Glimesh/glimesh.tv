defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Presence
  alias Glimesh.Streams

  def mount(%{"username" => streamer_username}, session, socket) do
    case Streams.get_by_username(streamer_username) do
      %Glimesh.Accounts.User{} = streamer ->
        # Keep track of viewers using their socket ID, but later we'll keep track of chatters by their user
        Presence.track_presence(self(), "viewer_count:#{streamer_username}", socket.id, %{})

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        # If the viewer is logged in set their locale, otherwise it defaults to English
        if session["locale"], do: Gettext.put_locale(session["locale"])

        {:ok,
         socket
         |> assign(:page_title, "#{streamer_username}'s Live Stream")
         |> assign(:streamer, streamer)
         |> assign(:playback_url, "/examples/big_buck_bunny_720p_surround.ogv")
         # this will be nil, which our children components handle
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end
end
