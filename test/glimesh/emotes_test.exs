defmodule Glimesh.EmotesTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Emotes
  alias Glimesh.Emotes.Emote

  @valid_attrs %{
    emote: "someemote",
    animated: false,
    static_file: %Plug.Upload{
      content_type: "image/svg+xml",
      path: "test/assets/glimchef.svg",
      filename: "glimchef.svg"
    },
    animated_file: %Plug.Upload{
      content_type: "image/gif",
      path: "test/assets/glimdance.gif",
      filename: "glimdance.gif"
    }
  }

  describe "emotes context" do
    setup do
      streamer = streamer_fixture()

      {:ok, streamer: streamer, channel: streamer.channel, admin: admin_fixture()}
    end

    test "create_global_emote/2 with valid data creates a regular emote", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @valid_attrs)
      assert emote.emote == "someemote"
    end

    test "create_global_emote/2 with valid data creates an animated emote", %{admin: admin} do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_global_emote(admin, %{
                 emote: "animated",
                 animated: true,
                 gif_file: "somefile.gif"
               })

      assert emote.emote == "animated"
    end

    test "create_channel_emote/3 as an admin creates an emote", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(streamer, channel, @valid_attrs)

      assert emote.emote == "someemote"
    end

    test "create_channel_emote/3 as a streamer creates an emote", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(streamer, channel, @valid_attrs)

      assert emote.emote == "someemote"
    end

    test "create_global_emote/2 as a regular user errors", %{streamer: streamer} do
      assert {:error, :unauthorized} = Emotes.create_global_emote(streamer, @valid_attrs)
    end

    test "create_global_emote/2 with with static image works", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @valid_attrs)
      assert emote.emote == "someemote"
    end

    test "create_global_emote/2 with with animated image works", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @valid_attrs)
      assert emote.emote == "someemote"
    end
  end
end
