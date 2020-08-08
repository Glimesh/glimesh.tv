defmodule GlimeshWeb.UserLive.Profile do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])

        [_, video_id] = Regex.run(~r/.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/, streamer.youtube_intro_url)

        {:ok,
         socket
         |> assign(:page_title, "#{streamer.displayname}'s Profile")
         |> assign(:following_count, Streams.count_following(streamer))
         |> assign(:followers_count, Streams.count_followers(streamer))
         |> assign(:youtube_id, video_id)
         |> assign(:streamer, streamer)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
