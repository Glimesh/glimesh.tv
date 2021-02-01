defmodule Glimesh.ChannelLookupsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.ChannelLookups
  alias Glimesh.ChannelCategories

  defp create_channel(_) do
    streamer =
      streamer_fixture(%{}, %{
        # Force ourselves to have a gaming stream
        category_id: ChannelCategories.get_category("gaming").id
      })

    %{
      channel: streamer.channel,
      streamer: streamer
    }
  end

  describe "channel lookups" do
    setup :create_channel

    test "list_channels/0 lists all channels" do
      assert length(ChannelLookups.list_channels()) == 1
    end

    test "filter_live_channels/0 lists all live channels", %{channel: channel} do
      assert length(ChannelLookups.filter_live_channels()) == 0

      {:ok, _} = Glimesh.Streams.start_stream(channel)
      assert length(ChannelLookups.filter_live_channels()) == 1

      assert Enum.member?(
               Enum.map(ChannelLookups.filter_live_channels(), fn x -> x.id end),
               channel.id
             )
    end

    test "filter_live_channels/1 filters by category", %{channel: gaming_channel} do
      art_streamer =
        streamer_fixture(%{}, %{
          category_id: ChannelCategories.get_category("art").id
        })

      {:ok, _} = Glimesh.Streams.start_stream(art_streamer.channel)
      {:ok, _} = Glimesh.Streams.start_stream(gaming_channel)

      gaming_channels = ChannelLookups.filter_live_channels(%{"category" => "gaming"})
      assert length(gaming_channels) == 1

      assert Enum.member?(
               Enum.map(gaming_channels, fn x -> x.id end),
               gaming_channel.id
             )

      refute Enum.member?(
               Enum.map(gaming_channels, fn x -> x.id end),
               art_streamer.channel.id
             )
    end

    test "filter_live_channels/1 filters by tag", %{channel: channel} do
      cat_id = ChannelCategories.get_category("gaming").id
      {:ok, some_tag} = ChannelCategories.create_tag(%{name: "Some Tag", category_id: cat_id})

      {:ok, _} =
        channel
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [some_tag])
        |> Glimesh.Repo.update()

      {:ok, _} = Glimesh.Streams.start_stream(channel)

      channels =
        ChannelLookups.filter_live_channels(%{"category" => "gaming", "tag" => "some-tag"})

      assert length(channels) == 1
    end

    test "list_live_followed_channels/1 lists live followed channels", %{
      streamer: streamer,
      channel: channel
    } do
      user = user_fixture()
      {:ok, _} = Glimesh.Streams.follow(streamer, user)

      assert length(ChannelLookups.list_live_followed_channels(user)) == 0

      {:ok, _} = Glimesh.Streams.start_stream(channel)
      assert length(ChannelLookups.list_live_followed_channels(user)) == 1
    end
  end
end
