defmodule Glimesh.ChannelLookupsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.ChannelLookups
  alias Glimesh.ChannelCategories
  alias Glimesh.Repo

  defp create_channel(_) do
    gaming_id = ChannelCategories.get_category("gaming").id

    {:ok, subcategory} =
      ChannelCategories.create_subcategory(%{
        name: "Testing",
        category_id: gaming_id
      })

    streamer =
      streamer_fixture(%{}, %{
        # Force ourselves to have a gaming stream
        category_id: gaming_id,
        subcategory_id: subcategory.id,
        language: "en"
      })

    tag = tag_fixture(%{name: "Some Tag", category_id: gaming_id})

    {:ok, channel} =
      streamer.channel
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, [tag])
      |> Glimesh.Repo.update()

    {:ok, _} = Glimesh.Streams.start_stream(channel)

    %{
      subcategory: subcategory,
      channel: channel,
      streamer: streamer
    }
  end

  describe "channel lookups" do
    setup :create_channel

    test "list_channels/0 lists all channels" do
      assert length(Repo.all(ChannelLookups.list_channels())) == 1
    end

    test "channel_search/1 lists channels conditionally for category", %{channel: channel} do
      random_streamer =
        streamer_fixture(%{}, %{category_id: ChannelCategories.get_category("art").id})

      {:ok, _} = Glimesh.Streams.start_stream(random_streamer.channel)

      channels =
        ChannelLookups.search_live_channels(%{
          "category" => "gaming"
        })

      assert length(channels) == 1
      assert hd(channels).id == channel.id
    end

    test "channel_search/1 lists channels conditionally for category and subcategory", %{
      channel: channel
    } do
      gaming_id = ChannelCategories.get_category("gaming").id

      {:ok, another_subcategory} =
        ChannelCategories.create_subcategory(%{
          name: "Not the one",
          category_id: gaming_id
        })

      random_streamer =
        streamer_fixture(%{}, %{category_id: gaming_id, subcategory_id: another_subcategory.id})

      {:ok, _} = Glimesh.Streams.start_stream(random_streamer.channel)

      channels =
        ChannelLookups.search_live_channels(%{
          "category" => "gaming",
          "subcategory" => ["testing"]
        })

      assert length(channels) == 1
      assert hd(channels).id == channel.id
    end

    test "channel_search/1 searches by tags", %{
      channel: channel
    } do
      random_streamer =
        streamer_fixture(%{}, %{category_id: ChannelCategories.get_category("gaming").id})

      Glimesh.Streams.start_stream(random_streamer.channel)

      channels =
        ChannelLookups.search_live_channels(%{
          "category" => "gaming",
          "tags" => ["some-tag"]
        })

      assert length(channels) == 1
      assert hd(channels).id == channel.id
    end

    test "channel_search/1 searches by languages", %{
      channel: channel
    } do
      random_streamer =
        streamer_fixture(%{}, %{
          category_id: ChannelCategories.get_category("gaming").id,
          language: "es_AR"
        })

      Glimesh.Streams.start_stream(random_streamer.channel)

      channels =
        ChannelLookups.search_live_channels(%{
          "category" => "gaming",
          "language" => ["en"]
        })

      assert length(channels) == 1
      assert hd(channels).id == channel.id

      channels =
        ChannelLookups.search_live_channels(%{
          "category" => "gaming",
          "language" => "en"
        })

      assert length(channels) == 1
      assert hd(channels).id == channel.id
    end

    test "list_live_channels/0 lists all live channels", %{} do
      assert length(ChannelLookups.list_live_channels()) == 1
    end

    test "list_live_followed_channels/1 lists live followed channels", %{
      streamer: streamer,
      channel: channel
    } do
      user = user_fixture()
      {:ok, _} = Glimesh.AccountFollows.follow(streamer, user)

      assert length(ChannelLookups.list_live_followed_channels(user)) == 1

      {:ok, _} = Glimesh.Streams.end_stream(channel)
      assert length(ChannelLookups.list_live_followed_channels(user)) == 0
    end

    test "get_channel_for_user_id/2 ignore ban check", %{
      streamer: streamer
    } do
      channel = ChannelLookups.get_channel_for_user_id(streamer.id, true)

      assert channel.user.username == streamer.username
    end
  end
end
