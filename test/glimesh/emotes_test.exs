defmodule Glimesh.EmotesTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Emotes
  alias Glimesh.Emotes.Emote

  @static_attrs %{
    emote: "someemote",
    animated: false,
    static_file: %Plug.Upload{
      content_type: "image/svg+xml",
      path: "test/assets/glimchef.svg",
      filename: "glimchef.svg"
    }
  }

  @animated_attrs %{
    emote: "animated",
    animated: true,
    animated_file: %Plug.Upload{
      content_type: "image/gif",
      path: "test/assets/glimdance.gif",
      filename: "glimdance.gif"
    }
  }

  describe "emotes context" do
    setup do
      streamer = streamer_fixture()

      {:ok, channel} =
        Glimesh.Streams.update_emote_settings(streamer, streamer.channel, %{
          emote_prefix: "testg"
        })

      {:ok, streamer: streamer, channel: channel, admin: admin_fixture()}
    end

    test "create_global_emote/2 with valid data creates a regular emote", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @static_attrs)
      assert emote.emote == "someemote"
      assert emote.static_file.file_name == "glimchef.svg"
    end

    test "create_global_emote/2 with valid data creates an animated emote", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @animated_attrs)

      assert emote.emote == "animated"
      assert emote.animated_file.file_name == "glimdance.gif"
    end

    test "create_global_emote/2 with a path works", %{admin: admin} do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_global_emote(admin, %{
                 emote: "someemote",
                 animated: false,
                 static_file: "test/assets/glimchef.svg"
               })

      assert emote.emote == "someemote"
    end

    test "create_channel_emote/3 as an admin creates an emote", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(streamer, channel, @static_attrs)

      assert emote.emote == "testgsomeemote"
    end

    test "create_channel_emote/3 as a streamer creates an emote", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(streamer, channel, @static_attrs)

      assert emote.emote == "testgsomeemote"
    end

    test "create_global_emote/2 as a regular user errors", %{streamer: streamer} do
      assert {:error, :unauthorized} = Emotes.create_global_emote(streamer, @static_attrs)
    end

    test "create_global_emote/2 with with static image works", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @static_attrs)
      assert emote.emote == "someemote"
    end

    test "create_global_emote/2 with with animated image works", %{admin: admin} do
      assert {:ok, %Emote{} = emote} = Emotes.create_global_emote(admin, @static_attrs)
      assert emote.emote == "someemote"
    end
  end
end
