defmodule Glimesh.EmotesTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Emotes
  alias Glimesh.Emotes.Emote

  @valid_attrs %{
    emote: "someemote",
    animated: false,
    png_file: "somefile.png",
    svg_file: "somefile.svg"
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
  end
end
