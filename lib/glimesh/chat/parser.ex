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
    defstruct allow_links: true, allow_glimojis: true, allow_animated_glimjois: false
  end

  defmodule Part do
    @enforce_keys [:type, :text]
    defstruct [:type, :text, :url, :huge]
  end

  import Phoenix.HTML
  import Phoenix.HTML.Tag
  alias Phoenix.HTML.Link

  @hyperlink_regex ~r/ (?:(?:https?|ftp)
                        :\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))
                        ?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?
                      /xi

  def type_parser(chat_message, %Config{} = config \\ %Config{}) do
    msg = String.split(chat_message)

    glimojis = Glimesh.Emote.list_emotes_by_key_and_image(config.allow_animated_glimjois)

    msg = if config.allow_glimojis, do: new_replace_glimojies(glimojis, msg), else: msg
    msg = if config.allow_links, do: new_replace_links(msg), else: msg

    new_replace_texts(msg)
  end

  defp new_replace_glimojies(glimojis, inputs) when length(inputs) == 1 do
    [new_glimoji_to_img(glimojis, hd(inputs), true)]
  end

  defp new_replace_glimojies(glimojis, inputs) do
    Enum.map(inputs, &new_glimoji_to_img(glimojis, &1))
  end

  defp new_replace_links(inputs) do
    Enum.map(inputs, &new_link_to_a(&1))
  end

  defp new_replace_texts(inputs) do
    Enum.map(inputs, &new_text_to_part(&1))
  end

  defp new_glimoji_to_img(_, %Part{} = inp, _), do: inp

  defp new_glimoji_to_img(glimojis, word, huge \\ false) do
    case Map.get(glimojis, word) do
      nil ->
        word

      img_path ->
        %Part{
          type: "emote",
          text: word,
          url: GlimeshWeb.Router.Helpers.static_url(GlimeshWeb.Endpoint, img_path),
          huge: huge
        }
    end
  end

  defp new_link_to_a(%Part{} = inp), do: inp

  defp new_link_to_a(link) do
    case URI.parse(link).scheme do
      link when link in ["https", "http"] ->
        %Part{
          type: "url",
          text: link,
          url: link
        }

      _ ->
        link
    end
  end

  defp new_text_to_part(%Part{} = inp), do: inp

  defp new_text_to_part(text) do
    %Part{
      type: "text",
      text: text
    }
  end

  # Parser
  def parse(chat_message, %Config{} = config \\ %Config{}) do
    msg = String.split(chat_message)

    glimojis = Glimesh.Emote.list_emotes_by_key_and_image(config.allow_animated_glimjois)

    msg = if config.allow_glimojis, do: replace_glimojies(glimojis, msg), else: msg
    msg = if config.allow_links, do: replace_links(msg), else: msg

    msg
  end

  def parse_and_render(
        %Glimesh.Chat.ChatMessage{} = chat_message,
        %Config{} = config \\ %Config{}
      ) do
    # If the user who posted the ChatMessage has a platform subscription, we allow animated emotes
    config =
      Map.put(
        config,
        :allow_animated_glimjois,
        Glimesh.Payments.has_platform_subscription?(chat_message.user)
      )

    chat_message.message
    |> parse(config)
    |> to_raw_html()
    |> raw()
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

  defp replace_glimojies(glimojis, inputs) when length(inputs) == 1 do
    [glimoji_to_img(glimojis, hd(inputs), "128px")]
  end

  defp replace_glimojies(glimojis, inputs) do
    Enum.map(inputs, &glimoji_to_img(glimojis, &1))
  end

  defp replace_links(inputs) do
    Enum.map(inputs, &link_to_a(&1))
  end

  defp glimoji_to_img(glimojis, word, size \\ "32px")
  defp glimoji_to_img(_, {:safe, _} = inp, _), do: inp

  defp glimoji_to_img(glimojis, word, size) do
    case Map.get(glimojis, word) do
      nil ->
        word

      img_path ->
        img_tag(GlimeshWeb.Router.Helpers.static_path(GlimeshWeb.Endpoint, img_path),
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
  def to_raw_html(safe_list) do
    safe_list
    |> Enum.map(&map_to_safe(&1))
    |> Enum.join(" ")
  end

  defp map_to_safe({:safe, _} = inp) do
    safe_to_string(inp)
  end

  defp map_to_safe(inp) do
    inp |> html_escape() |> map_to_safe()
  end
end
