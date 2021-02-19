defmodule GlimeshWeb.UserLive.Profile do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.Profile

  def mount(%{"username" => username}, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])

        video_id = Profile.youtube_video_id(streamer.youtube_intro_url)

        profile_url = Routes.user_profile_url(socket, :index, streamer.username)

        avatar_url = Glimesh.Avatar.url({streamer.avatar, streamer}, :original)

        streamer_share_text = Profile.streamer_share_text(streamer, profile_url)
        viewer_share_text = Profile.viewer_share_text(streamer, profile_url)

        {:ok,
         socket
         |> put_page_title("#{streamer.displayname}'s Profile")
         |> assign(:custom_meta, Profile.meta_tags(streamer, avatar_url))
         |> assign(:following_count, Glimesh.AccountFollows.count_following(streamer))
         |> assign(:followers_count, Glimesh.AccountFollows.count_followers(streamer))
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
