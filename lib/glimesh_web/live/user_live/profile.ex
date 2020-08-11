defmodule GlimeshWeb.UserLive.Profile do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  def mount(%{"username" => username}, session, socket) do
    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        if session["locale"], do: Gettext.put_locale(session["locale"]) # If the viewer is logged in set their locale, otherwise it defaults to English

        video_id = case Regex.run(~r/.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/, streamer.youtube_intro_url || "") do
          nil -> nil
          [_, video_id] -> video_id
        end

        profile_url = Routes.user_profile_url(socket, :index, streamer.username)

        streamer_share_text = URI.encode_www_form("Just created my @Glimesh Profile Page. I'll be streaming here when they launch but in the mean time you can follow me at #{profile_url}")
        viewer_share_text = if streamer.social_twitter do
          # just incase they included the URL or at symbol
          twitter_username = streamer.social_twitter |> String.replace_leading("https://twitter.com/", "") |> String.replace_leading("@", "")
          URI.encode_www_form("Just followed @#{twitter_username} on @Glimesh! I can't wait until they can start streaming! Check them out at #{profile_url}")
        else
          URI.encode_www_form("Just followed #{streamer.displayname} on @Glimesh! I can't wait until they can start streaming! Check them out at #{profile_url}")
        end

        {:ok,
         socket
         |> assign(:custom_meta, %{
          title: "#{streamer.displayname}'s Glimesh Profile",
          description: "#{streamer.displayname}'s new profile page on Glimesh, the next-gen live streaming platform.",
          image_url: Routes.static_url(socket, Glimesh.Avatar.url({streamer.avatar, streamer}, :original))
         })
         |> assign(:page_title, "#{streamer.displayname}'s Profile")
         |> assign(:following_count, Streams.count_following(streamer))
         |> assign(:followers_count, Streams.count_followers(streamer))
         |> assign(:youtube_id, video_id)
         |> assign(:streamer_share_text, streamer_share_text)
         |> assign(:viewer_share_text, viewer_share_text)
         |> assign(:streamer, streamer)
         |> assign(:user, maybe_user)
        }

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
