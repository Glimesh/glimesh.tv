defmodule Glimesh.BlogMigration do
  @moduledoc """
  Utility functions to help us migrate to a Hugo hosted blog.
  """

  require Logger

  def should_redirect(slug) do
    slug in get_historical_posts()
  end

  def list_recent_posts do
    Glimesh.QueryCache.get_and_store!("Glimesh.BlogMigration.list_recent_posts()", fn ->
      case get_recent_posts(5) do
        {:ok, posts} ->
          {:ok, posts}

        {:error, message} ->
          Logger.error("Error grabbing latest blog posts: #{message}")
          {:ok, []}
      end
    end)
  end

  defp get_historical_posts do
    [
      "2020-08-11-staff-meeting",
      "2020-08-13-glimesh-alpha-roadmap",
      "2020-08-18-staff-meeting",
      "2020-08-26-august-feature-update",
      "2020-09-15-staff-meeting",
      "2020-11-14-security-incident-oauth-key-exposure",
      "2020-12-16-december-roadmap-and-feature-update",
      "2021-01-29-the-glimcap-part-one",
      "2021-02-02-the-glimcap-week-two",
      "2021-02-11-the-glimcap-week-three",
      "2021-02-18-the-glimcap-week-four",
      "2021-02-23-the-glimcap-week-five",
      "2021-03-09-the-glimcap-week-six",
      "2021-03-16-the-glimcap-week-seven",
      "2021-03-23-the-glimcap-week-eight",
      "2021-03-30-the-glimcap-week-nine",
      "2021-04-06-the-glimcap-week-ten"
    ]
  end

  defp get_recent_posts(limit) do
    case HTTPoison.get("https://blog.glimesh.tv/index.xml") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {doc, []} = body |> :erlang.binary_to_list() |> :xmerl_scan.string()

        titles =
          :xmerl_xpath.string('/rss/channel/item/title/text()', doc)
          |> Enum.map(&parse_xml_text/1)

        urls =
          :xmerl_xpath.string('/rss/channel/item/link/text()', doc)
          |> Enum.map(&parse_xml_text/1)

        {:ok, Enum.zip(titles, urls) |> Enum.slice(0, limit)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Unexpected response from API."}

      _ ->
        {:error, "Unexpected response from API."}
    end
  end

  defp parse_xml_text({:xmlText, _, _, _, text, :text}) do
    text
  end

  defp parse_xml_text(_) do
    raise "Unknown input."
  end
end
