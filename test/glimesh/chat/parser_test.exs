defmodule Glimesh.Chat.ParserTest do
  use Glimesh.DataCase

  import Glimesh.EmotesFixtures

  alias Glimesh.Chat.Parser
  alias Glimesh.Chat.Token

  # If you are making changes to the parser and you'd like to benchmark it
  #       {benchmark, :ok} =
  #    :timer.tc(fn ->
  #      Parser.parse(
  #        "https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: https://glimesh.tv :glimwow: "
  #      )
  #
  #      :ok
  #    end)
  #
  #  IO.puts("Time to Parser: #{benchmark}μs") ~186μs on a Mac M1 16GB

  describe "chat parser" do
    setup do
      %{static: static_global_emote_fixture(), animated: animated_global_emote_fixture()}
    end

    test "lexes a simple message", %{static: static, animated: animated} do
      default_config = %Parser.Config{user_id: 1}
      assert Parser.parse("", default_config) == [%Token{type: "text", text: ""}]

      assert Parser.parse("Hello world", default_config) == [
               %Token{type: "text", text: "Hello world"}
             ]

      assert Parser.parse(":glimchef:", default_config) == [
               %Token{
                 type: "emote",
                 text: ":glimchef:",
                 src: Glimesh.Emotes.full_url(static)
               }
             ]

      allow_animated_emotes = %Parser.Config{allow_animated_emotes: true, user_id: 1}

      assert Parser.parse(":glimdance:", allow_animated_emotes) == [
               %Token{
                 type: "emote",
                 text: ":glimdance:",
                 src: Glimesh.Emotes.full_url(animated)
               }
             ]

      assert Parser.parse("https://glimesh.tv", default_config) == [
               %Token{type: "url", text: "https://glimesh.tv", url: "https://glimesh.tv"}
             ]

      assert Parser.parse("http://glimesh.tv", default_config) == [
               %Token{type: "url", text: "http://glimesh.tv", url: "http://glimesh.tv"}
             ]

      assert Parser.parse("glimesh.tv", default_config) == [
               %Token{type: "text", text: "glimesh.tv"}
             ]

      # Make sure we're not confusing a dot at the end for a URL
      assert Parser.parse("example.", default_config) == [%Token{type: "text", text: "example."}]
    end

    test "respects the config", %{static: static} do
      no_links = %Parser.Config{allow_links: false, user_id: 1}
      no_emotes = %Parser.Config{allow_emotes: false, user_id: 1}
      no_animated_emotes = %Parser.Config{allow_animated_emotes: false, user_id: 1}

      assert Parser.parse("https://example.com/", no_links) == [
               %Token{type: "text", text: "https://example.com/"}
             ]

      assert Parser.parse(":glimchef:", no_emotes) == [
               %Token{type: "text", text: ":glimchef:"}
             ]

      assert Parser.parse(":glimdance: :glimchef:", no_animated_emotes) == [
               %Token{type: "text", text: ":glimdance:"},
               %Token{type: "text", text: " "},
               %Token{
                 type: "emote",
                 text: ":glimchef:",
                 src: Glimesh.Emotes.full_url(static)
               }
             ]
    end

    test "allows animated emotes for channel, not for global" do
      # Reset the config just in case it's been changed
      Application.put_env(:glimesh, Glimesh.Emotes, allow_channel_animated_emotes: true)
      streamer = Glimesh.AccountsFixtures.streamer_fixture()

      {:ok, channel} =
        Glimesh.Streams.update_emote_settings(streamer, streamer.channel, %{
          emote_prefix: "testg"
        })

      {:ok, %Glimesh.Emotes.Emote{} = emote} =
        Glimesh.Emotes.create_channel_emote(streamer, channel, %{
          emote: "dance",
          animated: true,
          animated_file: "test/assets/glimdance.gif",
          approved_at: NaiveDateTime.utc_now()
        })

      no_animated_emotes = %Parser.Config{
        allow_animated_emotes: false,
        channel_id: channel.id,
        user_id: 1
      }

      assert Parser.parse(":glimdance: :testgdance:", no_animated_emotes) == [
               %Token{type: "text", text: ":glimdance:"},
               %Token{type: "text", text: " "},
               %Token{
                 type: "emote",
                 text: ":testgdance:",
                 src: Glimesh.Emotes.full_url(emote)
               }
             ]
    end

    test "lexes a complex message", %{static: static, animated: animated} do
      allow_animated_emotes = %Parser.Config{allow_animated_emotes: true, user_id: 1}

      parsed =
        Parser.parse(
          "Hello https://glimesh.tv :glimchef: world! How:glimdance:are https://google.com you!",
          allow_animated_emotes
        )

      assert parsed == [
               %Token{type: "text", text: "Hello "},
               %Token{type: "url", text: "https://glimesh.tv", url: "https://glimesh.tv"},
               %Token{type: "text", text: " "},
               %Token{type: "emote", text: ":glimchef:", src: Glimesh.Emotes.full_url(static)},
               %Token{type: "text", text: " world! How"},
               %Token{type: "emote", text: ":glimdance:", src: Glimesh.Emotes.full_url(animated)},
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
