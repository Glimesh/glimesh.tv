defmodule Glimesh.Chat.Renderer do
  @moduledoc """
  Converts a list of Glimesh.Chat.Token's into rendered HTML
  """
  use GlimeshWeb, :verified_routes

  alias Glimesh.Chat.Token

  def render([%Token{type: "emote", text: text, src: src}]) do
    # If we're just an emote, render big boy!
    [render_emote(text, src, "128px")]
    |> Enum.map(&map_to_safe(&1))
  end

  def render([%Token{type: "tenor", id: id, src: url, small_src: smallUrl}]) do
    [render_tenor_gif(id, url, smallUrl)]
    |> Enum.map(&map_to_safe(&1))
  end

  def render(unsafe_tokens) do
    Enum.map(unsafe_tokens, &render_token/1)
    |> Enum.map(&map_to_safe(&1))
  rescue
    ArgumentError -> "<em>Could not render message</em>"
    RuntimeError -> "<em>Could not render message</em>"
  end

  @doc """
  Shortcut function for testing mostly
  """
  def render_html(unsafe_tokens) do
    render(unsafe_tokens)
    |> Enum.join("")
  end

  def render_token(%Token{type: "text", text: text}) do
    text
  end

  def render_token(%Token{type: "emote", text: text, src: src}) do
    render_emote(text, src)
  end

  def render_token(%Token{type: "url", text: text, url: url}) do
    render_link(text, url)
  end

  def render_tenor_gif(%Token{type: "tenor", id: id, src: url, small_src: smallUrl}) do
    render_tenor_gif(id, url, smallUrl)
  end

  @doc """
  Renders a link into an anchor tag
  Safe?
  """
  def render_link(text, url) do
    Phoenix.HTML.Link.link(text, to: url, target: "_blank", rel: "ugc")
  end

  @doc """
  Render an emote into an img tag
  The inputs of this function are generally safe as `text` must strictly match an existing emote and `src` is generated by us.
  """
  def render_emote(text, src, size \\ "32px") do
    # Required for handling our new CDN hosted images
    # Could be removed if we regenerate all chat tokens
    src = append_local_path(src)

    Phoenix.HTML.Tag.tag(:img,
      src: src,
      width: size,
      height: size,
      draggable: "false",
      alt: text
    )
  end

  def render_tenor_gif(id, url, smallUrl) do
    Phoenix.HTML.Tag.tag(:img,
      src: url,
      style: "height: 55%; max-height: 220px; max-width:350px;",
      draggable: "false",
      "data-id": id,
      "data-small-url": smallUrl
    )
  end

  defp append_local_path("/" <> _ = src) do
    src
  end

  defp append_local_path(src) do
    src
  end

  defp map_to_safe({:safe, _} = inp) do
    # Safe tag that we generated
    Phoenix.HTML.safe_to_string(inp)
  end

  defp map_to_safe(inp) do
    # Unsafe user input
    inp |> Phoenix.HTML.html_escape() |> map_to_safe()
  end
end
