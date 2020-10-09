defmodule Glimesh.ChatParserTest do
  use Glimesh.DataCase

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
  end
end
