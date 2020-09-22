defmodule Glimesh.Emote do
  @moduledoc false

  def get_emotes do
    Application.get_env(:glimesh, :default_emotes)
  end

  def get_emote_names do
    Enum.map(get_emotes(), fn emote ->
      {name, _, _} = emote
      name
    end)
  end

  def parse(str) do
    names =
      Enum.map(get_emote_names(), fn name ->
        String.match?(str, ~r/#{name}/i)
      end)

    index = Enum.find_index(names, fn n -> n == true end)

    if is_integer(index) do
      case Enum.fetch(get_emotes(), index) do
        {:ok, {name, svg, _png}} ->
          parse(match_replace(str, ~r/#{name}/i, img_text(svg, String.replace(name, ":", ""))))

        :error ->
          str
      end
    else
      str
    end
  end

  defp match_replace(str, match, replace) do
    if String.match?(str, match) do
      String.replace(str, match, replace)
    else
      str
    end
  end

  defp img_text(src, alt) do
    "<img class=\"emoji\" draggable=\"false\" src=\"#{src}\" alt=\"#{alt}\">"
  end
end
