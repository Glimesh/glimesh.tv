defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams
  alias Glimesh.Presence

  def mount(%{"username" => streamer_username}, session, socket) do
    case Streams.get_by_username(String.downcase(streamer_username)) do
      %Glimesh.Accounts.User{} = streamer ->
        # Keep track of viewers using their socket ID, but later we'll keep track of chatters by their user
        Presence.track_presence(self(), "viewer_count:#{streamer_username}", socket.id, %{})

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])

        {:ok, socket
              |> assign(:page_title, "#{streamer_username}'s Live Stream")
              |> assign(:streamer, streamer)
              |> assign(:playback_url, "/examples/big_buck_bunny_720p_surround.ogv")
              |> assign(:user, maybe_user) # this will be nil, which our children components handle
        }

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end

  end

end
