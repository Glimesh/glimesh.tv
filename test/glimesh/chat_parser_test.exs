defmodule Glimesh.ChatParserTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.Chat.ChatMessage

  describe "chat parser" do
    test "parses a simple chat message" do
      parsed = Glimesh.Chat.Parser.parse("Hello world")
      assert parsed == ["Hello", "world"]
    end

    test "parses all the things" do
      parsed = Glimesh.Chat.Parser.parse(":glimwow: hello https://example.com/")

      assert Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "<img alt=\":glimwow:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimwow.svg\" width=\"32px\"> hello <a href=\"https://example.com/\" rel=\"ugc\" target=\"_blank\">https://example.com/</a>"
    end

    test "parses an average glimoji chat message" do
      parsed = Glimesh.Chat.Parser.parse("Hello :glimwow:")

      assert parsed == [
               "Hello",
               {:safe,
                [
                  60,
                  "img",
                  [
                    [32, "alt", 61, 34, ":glimwow:", 34],
                    [32, "draggable", 61, 34, "false", 34],
                    [32, "height", 61, 34, "32px", 34],
                    [32, "src", 61, 34, "/emotes/svg/glimwow.svg", 34],
                    [32, "width", 61, 34, "32px", 34]
                  ],
                  62
                ]}
             ]

      assert Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "Hello <img alt=\":glimwow:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimwow.svg\" width=\"32px\">"
    end

    test "parses an an animated emoji when the config allows" do
      parsed =
        Glimesh.Chat.Parser.parse("Hello :glimfury:", %Glimesh.Chat.Parser.Config{
          allow_animated_glimjois: true
        })

      assert Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "Hello <img alt=\":glimfury:\" draggable=\"false\" height=\"32px\" src=\"/emotes/gif/glimfury.gif\" width=\"32px\">"
    end

    test "DOES NOT parse a glimoji chat message with no spaces" do
      parsed = Glimesh.Chat.Parser.parse("Hello:glimwow:world")

      refute Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "Hello<img alt=\":glimwow:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimwow.svg\" width=\"32px\">world"
    end

    test "parses a large glimoji" do
      parsed = Glimesh.Chat.Parser.parse(":glimwow:")

      assert parsed == [
               {:safe,
                [
                  60,
                  "img",
                  [
                    [32, "alt", 61, 34, ":glimwow:", 34],
                    [32, "draggable", 61, 34, "false", 34],
                    [32, "height", 61, 34, "128px", 34],
                    [32, "src", 61, 34, "/emotes/svg/glimwow.svg", 34],
                    [32, "width", 61, 34, "128px", 34]
                  ],
                  62
                ]}
             ]
    end

    test "parses a link" do
      parsed = Glimesh.Chat.Parser.parse("https://example.com/")

      assert Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "<a href=\"https://example.com/\" rel=\"ugc\" target=\"_blank\">https://example.com/</a>"
    end

    test "parses a non-https link" do
      parsed = Glimesh.Chat.Parser.parse("http://example.com/")

      assert Glimesh.Chat.Parser.to_raw_html(parsed) ==
               "<a href=\"http://example.com/\" rel=\"ugc\" target=\"_blank\">http://example.com/</a>"
    end

    test "ignores a link when config disabled" do
      parsed =
        Glimesh.Chat.Parser.parse("https://example.com/", %Glimesh.Chat.Parser.Config{
          allow_links: false
        })

      assert Glimesh.Chat.Parser.to_raw_html(parsed) == "https://example.com/"
    end

    test "ignores a glimoji when config disabled" do
      parsed =
        Glimesh.Chat.Parser.parse(":glimwow:", %Glimesh.Chat.Parser.Config{
          allow_glimojis: false
        })

      assert Glimesh.Chat.Parser.to_raw_html(parsed) == ":glimwow:"
    end

    setup do
      %{
        user: user_fixture()
      }
    end

    test "html cannot be injected", %{user: user} do
      message = %ChatMessage{
        message: "<h2>Hello world</h2>",
        user: user
      }

      parsed = Glimesh.Chat.Parser.parse_and_render(message)

      assert Phoenix.HTML.safe_to_string(parsed) == "&lt;h2&gt;Hello world&lt;/h2&gt;"
    end

    test "html cannot be injected with a functional parser", %{user: user} do
      message = %ChatMessage{
        message: "<h2>Hello :glimwow: world</h2>",
        user: user
      }

      parsed = Glimesh.Chat.Parser.parse_and_render(message)

      assert Phoenix.HTML.safe_to_string(parsed) ==
               "&lt;h2&gt;Hello <img alt=\":glimwow:\" draggable=\"false\" height=\"32px\" src=\"/emotes/svg/glimwow.svg\" width=\"32px\"> world&lt;/h2&gt;"
    end
  end
end
