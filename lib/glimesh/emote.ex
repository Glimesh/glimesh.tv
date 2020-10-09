defmodule Glimesh.Emote do
  @moduledoc """
  Glimesh Custom Emote Handler
  """

  def list_emotes do
    Application.get_env(:glimesh, :emotes)
  end

  def list_emotes_for_js do
    Application.get_env(:glimesh, :emotes)
    |> Enum.map(fn {name, svg, _png} ->
      %{
        name: name,
        emoji: GlimeshWeb.Router.Helpers.static_url(GlimeshWeb.Endpoint, svg)
      }
    end)
    |> Jason.encode!()
  end

  def list_emote_identifiers do
    list_emotes()
    |> Enum.map(& &1)
  end

  def get_svg_by_identifier(id) do
    case Enum.find(list_emotes(), fn {name, _, _} -> name == id end) do
      {_, svg, _} -> svg
      _ -> nil
    end
  end
end
