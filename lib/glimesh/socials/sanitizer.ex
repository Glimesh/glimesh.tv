defmodule Glimesh.Socials.Sanitizer do
  @moduledoc """
  Sanitizes social usernames
  """

  def sanitize(nil), do: nil

  def sanitize(username) do
    username
    |> remove_at_symbol()
    |> String.trim(" ")
    |> String.trim("/")
  end

  def sanitize(username, :guilded) do
    username
    |> remove_guilded()
    |> sanitize()
  end

  defp remove_at_symbol(username) do
    String.trim_leading(username, "@")
  end

  defp remove_guilded(nil), do: nil

  defp remove_guilded(username) do
    case Regex.run(~r/[https?:\/\/]guilded.gg\/(.*)/, username, capture: :all_but_first) do
      nil -> username
      [match] -> match
    end
  end
end
