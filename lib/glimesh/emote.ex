defmodule Glimesh.Emote do
  def getEmotes() do
    Application.get_env(:glimesh, :default_emotes)
  end

  def getEmoteNames() do
    Enum.map(getEmotes(), fn emote ->
      {name, _, _} = emote
      name
    end)
  end

  def fullParse(str) do
    twemojiParse(parse(str))
  end

  def twemojiParse(str) do
    str
  end

  def parse(str) do
    names = Enum.map(getEmoteNames(), fn name ->
      String.match?(str, ~r/#{name}/i)
    end)
    index = Enum.find_index(names, fn n -> n == true end);
    if is_integer(index) do
      case Enum.fetch(getEmotes(), index) do
        {:ok, {name, svg, _png}} ->
          parse(matchReplace(str, ~r/#{name}/i, imgText(svg, String.replace(name, ":", ""))))
        :error -> str
      end
    else
      str
    end
  end

  defp matchReplace(str, match, replace) do
    if String.match?(str, match) do
      String.replace(str, match, replace)
    else
      str
    end
  end

  defp imgText(src, alt) do
    "<img class=\"emoji\" draggable=\"false\" src=\"#{src}\" alt=\"#{alt}\">"
  end
end
