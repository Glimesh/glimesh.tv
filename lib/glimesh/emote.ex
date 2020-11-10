defmodule Glimesh.Emote do
  @moduledoc """
  Glimesh Custom Emote Handler
  """

  def list_emotes do
    Application.get_env(:glimesh, :emotes)
  end

  def list_animated_emotes do
    Application.get_env(:glimesh, :animated_emotes)
  end

  def list_emotes_for_js(include_animated \\ false) do
    list_emotes_by_key_and_image(include_animated)
    |> Enum.map(fn {name, img} ->
      %{name: name, emoji: GlimeshWeb.Router.Helpers.static_url(GlimeshWeb.Endpoint, img)}
    end)
    |> Jason.encode!()
  end

  def list_emotes_by_key_and_image(include_animated \\ false) do
    regular =
      list_emotes()
      |> Enum.into(%{}, fn {name, images} -> {name, Map.get(images, :svg)} end)

    animated =
      if include_animated do
        list_animated_emotes()
        |> Enum.into(%{}, fn {name, images} -> {name, Map.get(images, :gif)} end)
      else
        %{}
      end

    Map.merge(regular, animated)
  end

  def list_emote_identifiers do
    list_emotes()
    |> Map.keys()
  end

  def get_svg_by_identifier(id) do
    list_emotes()
    |> get_in([id, :svg])
  end
end
