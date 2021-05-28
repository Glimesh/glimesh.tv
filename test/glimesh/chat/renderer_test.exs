defmodule Glimesh.Chat.RendererTest do
  use Glimesh.DataCase

  alias Glimesh.Chat.Renderer
  alias Glimesh.Chat.Parser
  alias Glimesh.Chat.Token

  describe "chat renderer" do
    test "renders a simple message" do
      assert Renderer.render_html([%Token{type: "text", text: "Hello world"}]) == "Hello world"

      assert Renderer.render_html([
               %Token{type: "emote", text: ":glimwow:", src: "/emotes/svg/glimwow.svg"}
             ]) ==
               "<img alt=\":glimwow:\" draggable=\"false\" height=\"128px\" src=\"/emotes/svg/glimwow.svg\" width=\"128px\">"

      assert Renderer.render_html([
               %Token{type: "url", text: "https://glimesh.tv", url: "https://glimesh.tv"}
             ]) ==
               "<a href=\"https://glimesh.tv\" rel=\"ugc\" target=\"_blank\">https://glimesh.tv</a>"

      assert Renderer.render_html([
               %Token{type: "url", text: "glimesh.tv", url: "http://glimesh.tv"}
             ]) ==
               "<a href=\"http://glimesh.tv\" rel=\"ugc\" target=\"_blank\">glimesh.tv</a>"
    end

    test "renders a complex message" do
      complex = [
        %Token{type: "text", text: "Hello "},
        %Token{type: "url", text: "https://glimesh.tv", url: "https://glimesh.tv"},
        %Token{type: "text", text: " "},
        %Token{type: "emote", text: ":glimwow:", src: "/emotes/svg/glimwow.svg"},
        %Token{type: "text", text: " world! How"},
        %Token{type: "emote", text: ":glimlove:", src: "/emotes/svg/glimlove.svg"},
        %Token{type: "text", text: "are "},
        %Token{type: "url", text: "https://google.com", url: "https://google.com"},
        %Token{type: "text", text: " you!"}
      ]

      assert Renderer.render_html(complex) ==
               "Hello <a href=\"https://glimesh.tv\" rel=\"ugc\" target=\"_blank\">https://glimesh.tv</a> <img alt=\":glimwow:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimwow.svg\" width=\"32px\"> world! How<img alt=\":glimlove:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimlove.svg\" width=\"32px\">are <a href=\"https://google.com\" rel=\"ugc\" target=\"_blank\">https://google.com</a> you!"
    end

    test "rendering prevents injection" do
      tokens = Parser.parse("<h2>Hello world</h2>")
      assert tokens == [%Token{type: "text", text: "<h2>Hello world</h2>"}]
      assert Renderer.render_html(tokens) == "&lt;h2&gt;Hello world&lt;/h2&gt;"

      emote = Glimesh.EmotesFixtures.static_global_emote_fixture()
      emote_url = Glimesh.Emotes.full_url(emote)

      tokens = Parser.parse("<h2>Hello :glimchef: world</h2>")

      assert tokens == [
               %Token{type: "text", text: "<h2>Hello "},
               %Token{type: "emote", src: emote_url, text: ":glimchef:"},
               %Token{type: "text", text: " world</h2>"}
             ]

      assert Renderer.render_html(tokens) ==
               "&lt;h2&gt;Hello <img alt=\":glimchef:\" draggable=\"false\" height=\"32px\" src=\"#{
                 emote_url
               }\" width=\"32px\"> world&lt;/h2&gt;"
    end
  end
end
