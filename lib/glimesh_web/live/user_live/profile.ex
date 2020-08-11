defmodule GlimeshWeb.UserLive.Profile do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile
  alias Glimesh.Streams

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])

        video_id = Profile.youtube_video_id(streamer.youtube_intro_url)

        profile_url = Routes.user_profile_url(socket, :index, streamer.username)

        avatar_url =
          Routes.static_url(socket, Glimesh.Avatar.url({streamer.avatar, streamer}, :original))

        streamer_share_text = Profile.streamer_share_text(streamer, profile_url)
        viewer_share_text = Profile.viewer_share_text(streamer, profile_url)

        {:ok,
         socket
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:page_title, "#{streamer.displayname}'s Profile")
         |> assign(:following_count, Streams.count_following(streamer))
         |> assign(:followers_count, Streams.count_followers(streamer))
         |> assign(:youtube_id, video_id)
         |> assign(:streamer_share_text, streamer_share_text)
         |> assign(:viewer_share_text, viewer_share_text)
         |> assign(:streamer, streamer)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
