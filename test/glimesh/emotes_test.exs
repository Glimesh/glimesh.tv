defmodule Glimesh.EmotesTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Emotes
  alias Glimesh.Emotes.Emote

  @static_attrs %{
    emote: "someemote",
    animated: false,
    approved_at: NaiveDateTime.utc_now(),
    static_file: %Plug.Upload{
      content_type: "image/svg+xml",
      path: "test/assets/glimchef.svg",
      filename: "glimchef.svg"
    }
  }

  @animated_attrs %{
    emote: "animated",
    animated: true,
    approved_at: NaiveDateTime.utc_now(),
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

    test "create_channel_emote/3 doesnt work if you dont have a prefix", %{} do
      streamer = streamer_fixture()

      assert {:error, changeset_error} =
               Emotes.create_channel_emote(streamer, streamer.channel, @static_attrs)

      assert changeset_error.errors == [emote: {"Emote prefix does not exist for channel", []}]
    end

    test "create_channel_emote/3 as a streamer creates an emote", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(
                 streamer,
                 channel,
                 Map.merge(@static_attrs, %{approved_at: nil})
               )

      assert emote.emote == "testgsomeemote"
      assert is_nil(emote.approved_at)
      assert emote.channel_id == channel.id

      assert Glimesh.Emotes.list_emotes_for_channel(channel) == []
    end

    test "create_channel_emote/3 requires approval to be used", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:ok, %Emote{} = emote} =
               Emotes.create_channel_emote(
                 streamer,
                 channel,
                 Map.merge(@static_attrs, %{approved_at: nil})
               )

      assert emote.emote == "testgsomeemote"

      assert Glimesh.Emotes.list_emotes_for_channel(channel) == []

      {:ok, emote} = Glimesh.Emotes.approve_emote(admin_fixture(), emote)
      emotes = Glimesh.Emotes.list_emotes_for_channel(channel)
      assert length(emotes) == 1
      assert hd(emotes).id == emote.id
    end

    test "create_channel_emote/3 respects config emote limit", %{
      streamer: streamer,
      channel: channel
    } do
      Application.put_env(:glimesh, Glimesh.Emotes, max_channel_emotes: 1)

      assert {:ok, _} = Emotes.create_channel_emote(streamer, channel, @static_attrs)

      assert {:error, changeset_error} =
               Emotes.create_channel_emote(
                 streamer,
                 channel,
                 Map.merge(@static_attrs, %{emote: "another"})
               )

      assert changeset_error.errors == [emote: {"You can only have 1 emotes at a time.", []}]
    end

    test "create_channel_emote/3 respects config animated emotes", %{
      streamer: streamer,
      channel: channel
    } do
      Application.put_env(:glimesh, Glimesh.Emotes, allow_channel_animated_emotes: false)

      assert {:error, changeset_error} =
               Emotes.create_channel_emote(streamer, channel, @animated_attrs)

      assert changeset_error.errors == [emote: {"You cannot upload animated emotes.", []}]
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

    test "list_emotes_for_js/1 includes global emotes", %{admin: admin} do
      assert {:ok, %Emote{}} = Emotes.create_global_emote(admin, @static_attrs)

      assert Emotes.list_emotes_for_js() =~ ":someemote:"
    end

    test "create_channel_emote/3 errors on large file", %{
      streamer: streamer,
      channel: channel
    } do
      too_large = %{
        emote: "toolarge",
        animated: false,
        static_file: %Plug.Upload{
          content_type: "image/svg+xml",
          path: "test/assets/too_large.svg",
          filename: "too_large.svg"
        }
      }

      assert {:error, changeset_error} = Emotes.create_channel_emote(streamer, channel, too_large)

      assert changeset_error.errors == [
               static_file:
                 {"is invalid",
                  [{:type, Glimesh.Uploaders.StaticEmote.Type}, {:validation, :cast}]}
             ]
    end

    test "create_channel_emote/3 errors on a bad emote name", %{
      streamer: streamer,
      channel: channel
    } do
      assert {:error, changeset_error} =
               Emotes.create_channel_emote(
                 streamer,
                 channel,
                 Map.merge(@static_attrs, %{emote: "test.name"})
               )

      assert changeset_error.errors == [
               emote:
                 {"Emote must be only contain alpha-numeric characters", [validation: :format]}
             ]
    end
  end
end
