defmodule Glimesh.Accounts.Profile do
  @moduledoc false

  alias Glimesh.Accounts.User

  def user_role_color(%User{team_role: team_role}) do
    case team_role do
      "Core Team" ->
        "bg-danger"

      "Community Team" ->
        "bg-success"

      "Design Team" ->
        "bg-info"

      "Product Dev Team" ->
        "bg-secondary"

      _ ->
        ""
    end
  end

  def safe_user_markdown_to_html(nil) do
    {:ok, nil}
  end

  def safe_user_markdown_to_html(profile_content_md) do
    case Earmark.as_html(profile_content_md) do
      {:ok, html_doc, []} ->
        {:ok, format_contents(html_doc)}

      {:ok, _, error_messages} ->
        {:error, format_earmark_messages(error_messages)}

      {:error, _, error_messages} ->
        {:error, format_earmark_messages(error_messages)}
    end
  end

  defp format_earmark_messages(error_messages) do
    Enum.map(error_messages, fn {_severity, line, message} ->
      "#{message} on line #{line}"
    end)
    |> Enum.join("\n")
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
    name =
      if twitter_user = Glimesh.Socials.get_social(streamer, "twitter") do
        twitter_user.username
      else
        if streamer.social_twitter do
          streamer.social_twitter
        else
          streamer.displayname
        end
      end

    URI.encode_www_form(
      "Just followed @#{name} on @Glimesh! I can't wait until they can start streaming! Check them out at #{
        profile_url
      }"
    )
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

  def format_contents(html_doc) do
    html_doc
    |> HtmlSanitizeEx.basic_html()
    |> format_images()
    |> links_in_new_tab()
  end

  defp links_in_new_tab(doc) do
    doc
    |> String.replace("<a ", "<a rel=\"ugc\" target=\"_blank\" ")
  end

  defp format_images(doc) do
    doc
    |> String.replace("\n  ", "")
    |> String.replace("\n</a>", "</a>")
    |> String.replace(">  <img", "><img")
    |> String.replace(">\n<a href", "><a href")
  end
end
