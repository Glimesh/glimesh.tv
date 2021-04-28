defmodule Glimesh.Socials.Sanitizer do
  @moduledoc """
  Sanitizes social usernames
  """

  def sanitize(username) do
    username
    |> remove_at_symbol()
    |> String.trim(" ")
    |> String.trim("/")
  end

  defp remove_at_symbol(username) do
    String.trim_leading(username, "@")
  end
end
