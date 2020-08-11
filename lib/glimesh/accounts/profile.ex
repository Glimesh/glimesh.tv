defmodule Glimesh.Accounts.Profile do
  def safe_user_markdown_to_html(profile_content_md) do
    {:ok, html_doc, []} = Earmark.as_html(profile_content_md)
    html_doc |> HtmlSanitizeEx.basic_html()
  end

  def youtube_video_id(youtube_intro_url) do
    case Regex.run(
           ~r/.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/,
           youtube_intro_url || ""
         ) do
      nil -> nil
      [_, video_id] -> video_id
    end
  end

  def viewer_share_text(streamer, profile_url) do
    if streamer.social_twitter do
      # just incase they included the URL or at symbol
      twitter_username =
        streamer.social_twitter
        |> String.replace_leading("https://twitter.com/", "")
        |> String.replace_leading("@", "")

      URI.encode_www_form(
        "Just followed @#{twitter_username} on @Glimesh! I can't wait until they can start streaming! Check them out at #{
          profile_url
        }"
      )
    else
      URI.encode_www_form(
        "Just followed #{streamer.displayname} on @Glimesh! I can't wait until they can start streaming! Check them out at #{
          profile_url
        }"
      )
    end
  end

  def streamer_share_text(_streamer, profile_url) do
    URI.encode_www_form(
      "Just created my @Glimesh Profile Page. I'll be streaming here when they launch but in the mean time you can follow me at #{
        profile_url
      }"
    )
  end

  def meta_tags(streamer, avatar_path) do
    %{
      title: "#{streamer.displayname}'s Glimesh Profile",
      description:
        "#{streamer.displayname}'s new profile page on Glimesh, the next-gen live streaming platform.",
      image_url: avatar_path
    }
  end
end
