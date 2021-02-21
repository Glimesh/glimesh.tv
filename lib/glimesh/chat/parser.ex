defmodule Glimesh.Chat.Parser do
  @moduledoc """
  Responsible for splitting a chat message into it's various tokens. The Glimesh.Chat.Renderer puts it back together for display.
  """

  defmodule Config do
    @moduledoc """
    Configuration for the parser
    """
    defstruct allow_links: true, allow_emotes: true, allow_animated_emotes: false, emotes: []
  end

  alias Glimesh.Chat.Token

  @emote_regex ~r/(?::\w+:)/
  # credo:disable-for-next-line
  @hyperlink_regex ~r/((https?):\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()!@:%_\+.~#?&\/\/=]*)/

  # Older hyperlink regex
  # credo:disable-for-next-line
  # @hyperlink_regex ~r/(?:(?:https?):\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?/

  def parse(chat_message, config \\ %Config{})

  def parse("", _) do
    [
      %Token{
        type: "text",
        text: ""
      }
    ]
  end

  def parse(chat_message, %Config{} = config) do
    emotes = Glimesh.Emote.list_emotes_by_key_and_image(config.allow_animated_emotes)
    config = Map.put(config, :emotes, emotes)

    parsed =
      [chat_message]
      |> split_with_regex(@hyperlink_regex)
      |> split_with_regex(@emote_regex)
      |> map_to_tokens(config)

    parsed
  end

  defp split_with_regex(items, regex) do
    Enum.map(items, fn item ->
      Regex.split(regex, item, include_captures: true, trim: true)
    end)
    |> List.flatten()
  end

  defp map_to_tokens(items, %Config{} = config) do
    # Yes, I'm sorry, I don't know how else to do this.
    Enum.map(items, fn item ->
      cond do
        config.allow_links and Regex.match?(@hyperlink_regex, item) ->
          url_token(item)

        config.allow_emotes and String.starts_with?(item, ":") ->
          # credo:disable-for-next-line
          case Map.get(config.emotes, item) do
            nil -> text_token(item)
            src -> emote_token(item, src)
          end

        true ->
          text_token(item)
      end
    end)
  end

  defp text_token(text) do
    %Token{
      type: "text",
      text: text
    }
  end

  defp url_token(link) do
    # Check if we need to normalize the URL
    %URI{scheme: scheme} = URI.parse(link)
    url = if scheme, do: link, else: "http://#{link}"

    %Token{
      type: "url",
      text: link,
      url: url
    }
  end

  defp emote_token(emote, src) do
    %Token{
      type: "emote",
      text: emote,
      src: src
    }
  end
end
