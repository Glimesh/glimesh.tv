defmodule Glimesh.Chat.ParserTest do
  use Glimesh.DataCase

  alias Glimesh.Chat.Parser
  alias Glimesh.Chat.Token

  describe "chat parser" do
    test "lexes a simple message" do
      assert Parser.parse("") == [%Token{type: "text", text: ""}]
      assert Parser.parse("Hello world") == [%Token{type: "text", text: "Hello world"}]

      assert Parser.parse(":glimwow:") == [
               %Token{type: "emote", text: ":glimwow:", src: "/emotes/svg/glimwow.svg"}
             ]

      assert Parser.parse("https://glimesh.tv") == [
               %Token{type: "url", text: "https://glimesh.tv", url: "https://glimesh.tv"}
             ]

      assert Parser.parse("http://glimesh.tv") == [
               %Token{type: "url", text: "http://glimesh.tv", url: "http://glimesh.tv"}
             ]

      assert Parser.parse("glimesh.tv") == [
               %Token{type: "url", text: "glimesh.tv", url: "http://glimesh.tv"}
             ]

      # Make sure we're not confusing a dot at the end for a URL
      assert Parser.parse("example.") == [%Token{type: "text", text: "example."}]
    end

    test "respects the config" do
      no_links = %Parser.Config{allow_links: false}
      no_emotes = %Parser.Config{allow_emotes: false}
      no_animated_emotes = %Parser.Config{allow_animated_emotes: false}

      assert Parser.parse("https://example.com/", no_links) == [
               %Token{type: "text", text: "https://example.com/"}
             ]

      assert Parser.parse(":glimwow:", no_emotes) == [
               %Token{type: "text", text: ":glimwow:"}
             ]

      assert Parser.parse(":glimfury: :glimwow:", no_animated_emotes) == [
               %Token{type: "text", text: ":glimfury:"},
               %Token{type: "text", text: " "},
               %Token{type: "emote", text: ":glimwow:", src: "/emotes/svg/glimwow.svg"}
             ]
    end

    test "lexes a complex message" do
      parsed =
        Parser.parse(
          "Hello https://glimesh.tv :glimwow: world! How:glimlove:are https://google.com you!"
        )

      {benchmark, :ok} =
        :timer.tc(fn ->
          Parser.parse(
            "https://glimesh.tv  f̷̧͖͈̂̿s̷̖͚̻͍̟͕͈̞͍̑̃̏̿̒d̴̡̦̟̜̪̭̥̖̟̦̮͍̳̤͚̃̈́̀͝f̶͍̤̳̯̱̙̖̲̽̈͒͆̿̄̿̆̀̚͝s̴̮̫̬͔̜͚̬̪̩̔̊͂͗́̌̑̚d̵̢͈̥̱̆̇̈́̎́̍͘͜͝ https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: "
          )

          :ok
        end)

      IO.puts("Time to Parser: #{benchmark}μs")

      assert parsed == [
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
    end
  end

  def measure(function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
