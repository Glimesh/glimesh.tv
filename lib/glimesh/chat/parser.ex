defmodule Glimesh.Chat.Parser do
  @moduledoc """
  Converts a simple input into a fully realized HTML output for the chat client.

  This is a simple parser, it essentially loops through a ever-growing list of strings or
  converted values, searching for any changes it needs to make, before reassembling it.
  """

  defmodule Config do
    @moduledoc """
    Configuration for the parser
    """
    defstruct allow_links: true, allow_glimojis: true
  end

  import Phoenix.HTML
  import Phoenix.HTML.Tag
  alias Phoenix.HTML.Link

  @hyperlink_regex ~r/ (?:(?:https?|ftp)
                        :\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))
                        ?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?
                      /xi

  # Parser
  def parse(chat_message, %Config{} = config \\ %Config{}) do
    msg = String.split(chat_message)

    msg = if config.allow_glimojis, do: replace_glimojies(msg), else: msg
    msg = if config.allow_links, do: replace_links(msg), else: msg

    msg
  end

  def message_contains_link(chat_message) do
    found_uris = flatten_list(Regex.scan(@hyperlink_regex, chat_message))

    for message <- found_uris do
      case URI.parse(message).scheme do
        "https" -> true
        "http" -> true
        _ -> false
      end
    end
  end

  defp replace_glimojies(inputs) when length(inputs) == 1 do
    [hd(inputs) |> glimoji_to_img("128px")]
  end

  defp replace_glimojies(inputs) do
    Enum.map(inputs, &glimoji_to_img(&1))
  end

  defp replace_links(inputs) do
    Enum.map(inputs, &link_to_a(&1))
  end

  defp glimoji_to_img(word, size \\ "32px")
  defp glimoji_to_img({:safe, _} = inp, _), do: inp

  defp glimoji_to_img(word, size) do
    case Glimesh.Emote.get_svg_by_identifier(word) do
      nil ->
        word

      svg ->
        img_tag(GlimeshWeb.Router.Helpers.static_path(GlimeshWeb.Endpoint, svg),
          width: size,
          height: size,
          draggable: "false",
          alt: word
        )
    end
  end

  defp link_to_a({:safe, _} = inp), do: inp

  defp link_to_a(link) do
    case URI.parse(link).scheme do
      "https" -> Link.link(link, to: link, target: "_blank", rel: "ugc")
      "http" -> Link.link(link, to: link, target: "_blank", rel: "ugc")
      _ -> link
    end
  end

  defp flatten_list([head | tail]), do: flatten_list(head) ++ flatten_list(tail)
  defp flatten_list([]), do: []
  defp flatten_list(element), do: [element]

  # Renderer

  def string_to_raw(input) do
    input
    |> parse()
    |> to_raw_html()
    |> raw()
  end

  def to_raw_html(safe_list) do
    safe_list
    |> Enum.map(&map_to_safe(&1))
    |> Enum.join(" ")
  end

  defp map_to_safe({:safe, _} = inp) do
    safe_to_string(inp)
  end

  defp map_to_safe(inp) do
    inp
  end
end
