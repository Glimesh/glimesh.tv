defmodule Glimesh.ChannelLookupsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  import Glimesh.StreamsFixtures
  alias Glimesh.ChannelLookups
  alias Glimesh.ChannelCategories
  alias Glimesh.Streams
  alias Glimesh.Streams.ChannelHosts

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
      assert length(ChannelLookups.list_channels()) == 1
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
  end

  defp account_ages(_) do
    %{
      five_days_ago:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 86_400 * -5) |> NaiveDateTime.truncate(:second),
      ten_days_from_now:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 86_400 * 10) |> NaiveDateTime.truncate(:second)
    }
  end

  defp create_hosting_data(_) do
    hosting_channel =
      streamer_fixture(%{}, %{})
      |> change_inserted_at_for_user(
        NaiveDateTime.add(NaiveDateTime.utc_now(), 86_400 * -6)
        |> NaiveDateTime.truncate(:second)
      )

    Streams.create_stream(hosting_channel.channel, %{
      started_at:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * -10)
        |> NaiveDateTime.truncate(:second),
      ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })

    %{
      target_allowed_hosting: streamer_fixture(%{}, %{allow_hosting: true}),
      hosting_channel_five_days_old: hosting_channel
    }
  end

  describe "Hosting Channels" do
    setup [:account_ages, :create_hosting_data]

    test "Banned user cannot be hosted", %{hosting_channel_five_days_old: hosting_channel} do
      banned_user = streamer_fixture(%{is_banned: true}, %{allow_hosting: true})

      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 banned_user.displayname
               )
             ) == 0
    end

    test "Users without channels cannot be hosted", %{
      hosting_channel_five_days_old: hosting_channel
    } do
      ordinary_user = user_fixture(%{})

      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 ordinary_user.displayname
               )
             ) == 0
    end

    test "Streamers banned from a channel cannot host channel", %{
      target_allowed_hosting: target_channel,
      hosting_channel_five_days_old: hosting_channel
    } do
      channel_banned_user_fixture(target_channel.channel, hosting_channel)

      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 target_channel.displayname
               )
             ) == 0
    end

    test "Streamers cannot host channels that don't allow hosting", %{
      hosting_channel_five_days_old: hosting_channel
    } do
      target_channel = streamer_fixture(%{}, %{allow_hosting: false})

      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 target_channel.displayname
               )
             ) == 0
    end

    test "Streamers cannot host their own channel", %{
      hosting_channel_five_days_old: hosting_channel
    } do
      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 hosting_channel.displayname
               )
             ) == 0
    end

    test "Streamers CAN host a channel", %{
      target_allowed_hosting: target_channel,
      hosting_channel_five_days_old: hosting_channel
    } do
      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 target_channel.displayname
               )
             ) == 1
    end

    test "Streamers timed out from a channel CAN host channel",
         %{
           target_allowed_hosting: target_channel,
           hosting_channel_five_days_old: hosting_channel,
           ten_days_from_now: ten_days_from_now
         } do
      channel_timed_out_user_fixture(target_channel.channel, hosting_channel, ten_days_from_now)

      assert length(
               ChannelLookups.search_hostable_channels_by_name(
                 hosting_channel,
                 target_channel.displayname
               )
             ) == 1
    end

    test "Streamers CAN find more than one channel to host",
         %{
           target_allowed_hosting: _target_channel,
           hosting_channel_five_days_old: hosting_channel,
           ten_days_from_now: ten_days_from_now
         } do
      _target_channel_one = streamer_fixture(%{}, %{allow_hosting: true})
      _target_channel_two = streamer_fixture(%{}, %{allow_hosting: true})
      target_channel_three = streamer_fixture(%{}, %{allow_hosting: true})

      channel_timed_out_user_fixture(
        target_channel_three.channel,
        hosting_channel,
        ten_days_from_now
      )

      # banned
      _bad_target_one = streamer_fixture(%{is_banned: true}, %{allow_hosting: true})
      # doesn't allow hosting
      _bad_target_two = streamer_fixture(%{}, %{allow_hosting: false})
      # ordinary user, no channel
      _bad_target_three = user_fixture(%{})
      bad_target_four = streamer_fixture(%{}, %{allow_hosting: true})
      # hosting channel banned from target
      channel_banned_user_fixture(bad_target_four.channel, hosting_channel)

      # includes target_channel
      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, "user")) == 4
    end

    test "Already hosted channels should be filtered out of search", %{
      target_allowed_hosting: target_channel,
      hosting_channel_five_days_old: hosting_channel
    } do
      case ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
             hosting_channel_id: hosting_channel.channel.id,
             target_channel_id: target_channel.channel.id
           }) do
        {:ok, _channel_hosts} ->
          assert length(
                   ChannelLookups.search_hostable_channels_by_name(
                     hosting_channel,
                     target_channel.displayname
                   )
                 ) == 0

        {:error, _channel_hosts} ->
          flunk("Unable to setup channel host")
      end
    end

    test "Already hosted channels should show up in other users searches", %{
      target_allowed_hosting: target_channel,
      hosting_channel_five_days_old: hosting_channel
    } do
      %{hosting_channel_five_days_old: other_channel} = create_hosting_data(%{})

      case ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
             hosting_channel_id: hosting_channel.channel.id,
             target_channel_id: target_channel.channel.id
           }) do
        {:ok, _channel_hosts} ->
          assert length(
                   ChannelLookups.search_hostable_channels_by_name(
                     other_channel,
                     target_channel.displayname
                   )
                 ) == 1

        {:error, _channel_hosts} ->
          flunk("Unable to setup channel host")
      end
    end

    test "Search terms should be sanitized", %{hosting_channel_five_days_old: hosting_channel} do
      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, "user_")) ==
               0

      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, "%user")) ==
               0

      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, "user%")) ==
               0

      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, "%user_%")) ==
               0
    end

    test "Search terms must be less than username max size", %{
      hosting_channel_five_days_old: hosting_channel
    } do
      bad_search = "0123456789012345678901234"

      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, bad_search)) ==
               0

      bad_search = nil

      assert length(ChannelLookups.search_hostable_channels_by_name(hosting_channel, bad_search)) ==
               0
    end
  end

  defp create_followed_hosting_data(_) do
    user = user_fixture()
    additional_follower = user_fixture()
    non_followed_live_channel = streamer_fixture()

    Ecto.Changeset.change(non_followed_live_channel.channel)
    |> Ecto.Changeset.force_change(:status, "live")
    |> Repo.update()

    live_channel_hosted = streamer_fixture(%{}, %{status: "live"})
    # make sure hosted channels have more than one follower
    Glimesh.AccountFollows.follow(live_channel_hosted, additional_follower)

    Ecto.Changeset.change(live_channel_hosted.channel)
    |> Ecto.Changeset.force_change(:status, "live")
    |> Repo.update()

    host = streamer_fixture()

    Ecto.Changeset.change(%Glimesh.Streams.ChannelHosts{
      hosting_channel_id: host.channel.id,
      target_channel_id: live_channel_hosted.channel.id,
      status: "hosting"
    })
    |> Repo.insert()

    Glimesh.AccountFollows.follow(host, user)
    Glimesh.AccountFollows.follow(host, additional_follower)

    live_channel_hosted_but_not_followed = streamer_fixture()

    Ecto.Changeset.change(live_channel_hosted_but_not_followed.channel)
    |> Ecto.Changeset.force_change(:status, "live")
    |> Repo.update()

    host_not_followed = streamer_fixture()

    Ecto.Changeset.change(%Glimesh.Streams.ChannelHosts{
      hosting_channel_id: host_not_followed.channel.id,
      target_channel_id: live_channel_hosted_but_not_followed.channel.id,
      status: "hosting"
    })
    |> Repo.insert()

    live_channel_followed_but_not_hosted = streamer_fixture()

    Ecto.Changeset.change(live_channel_followed_but_not_hosted.channel)
    |> Ecto.Changeset.force_change(:status, "live")
    |> Repo.update()

    Glimesh.AccountFollows.follow(live_channel_followed_but_not_hosted, user)
    Glimesh.AccountFollows.follow(live_channel_followed_but_not_hosted, additional_follower)

    %{
      user: user,
      host: host,
      live_channel_hosted: live_channel_hosted,
      non_followed_live_channel: non_followed_live_channel,
      live_channel_hosted_but_not_followed: live_channel_hosted_but_not_followed,
      host_not_followed: host_not_followed,
      live_channel_followed_but_not_hosted: live_channel_followed_but_not_hosted
    }
  end

  describe "Followed hosting channels" do
    setup [:create_followed_hosting_data]

    test "should show up in the search when the followed channel is not live", %{
      user: user,
      live_channel_hosted: live_hosted,
      live_channel_followed_but_not_hosted: live_followed
    } do
      results = ChannelLookups.list_live_followed_channels_and_hosts(user)
      assert length(results) == 2
      assert Enum.at(results, 0).id == live_followed.channel.id
      assert Enum.at(results, 0).match_type == "live"
      assert Enum.at(results, 1).id == live_hosted.channel.id
      assert Enum.at(results, 1).match_type == "hosting"
    end

    test "should NOT show duplicates when followed channels host the same live channel", %{
      user: user,
      live_channel_hosted: live_hosted,
      live_channel_followed_but_not_hosted: live_followed
    } do
      followed_channel_same_host_target = streamer_fixture()
      Glimesh.AccountFollows.follow(followed_channel_same_host_target, user)

      Ecto.Changeset.change(%Glimesh.Streams.ChannelHosts{
        hosting_channel_id: followed_channel_same_host_target.channel.id,
        target_channel_id: live_hosted.channel.id,
        status: "hosting"
      })
      |> Repo.insert()

      results = ChannelLookups.list_live_followed_channels_and_hosts(user)
      assert length(results) == 2
      assert Enum.at(results, 0).id == live_followed.channel.id
      assert Enum.at(results, 0).match_type == "live"
      assert Enum.at(results, 1).id == live_hosted.channel.id
      assert Enum.at(results, 1).match_type == "hosting"
    end

    test "should show followed live channel without duplicating it when it is hosted by an offline channel that is followed",
         %{
           user: user,
           live_channel_hosted: live_hosted,
           live_channel_followed_but_not_hosted: live_followed
         } do
      followed_offline_channel_same_host_target = streamer_fixture()
      Glimesh.AccountFollows.follow(followed_offline_channel_same_host_target, user)

      Ecto.Changeset.change(%Glimesh.Streams.ChannelHosts{
        hosting_channel_id: followed_offline_channel_same_host_target.channel.id,
        target_channel_id: live_followed.channel.id,
        status: "hosting"
      })
      |> Repo.insert()

      results = ChannelLookups.list_live_followed_channels_and_hosts(user)
      assert length(results) == 2
      assert Enum.at(results, 0).id == live_followed.channel.id
      assert Enum.at(results, 0).match_type == "live"
      assert Enum.at(results, 1).id == live_hosted.channel.id
      assert Enum.at(results, 1).match_type == "hosting"
    end

    test "should prefer live channels over hosted when duplicates occur", %{
      user: user,
      live_channel_hosted: live_hosted,
      live_channel_followed_but_not_hosted: live_followed
    } do
      # sanity check
      results = ChannelLookups.list_live_followed_channels_and_hosts(user)
      assert length(results) == 2
      assert Enum.at(results, 0).id == live_followed.channel.id
      assert Enum.at(results, 0).match_type == "live"
      assert Enum.at(results, 1).id == live_hosted.channel.id
      assert Enum.at(results, 1).match_type == "hosting"

      # if the user follows the channel being hosted, it should show up in the live section and not as a "hosted" stream.
      Glimesh.AccountFollows.follow(live_hosted, user)
      results = ChannelLookups.list_live_followed_channels_and_hosts(user)
      assert length(results) == 2
      # I don't do an ID check here as the results are not sorted and could be random
      assert Enum.at(results, 0).match_type == "live"
      assert Enum.at(results, 1).match_type == "live"
    end

    test "followed channels and followed hosted channels counts should be accurate", %{
      user: user,
      live_channel_hosted: live_hosted
    } do
      assert ChannelLookups.count_live_followed_channels_that_are_hosting(user) == 1
      assert length(ChannelLookups.list_live_followed_channels(user)) == 1

      Glimesh.AccountFollows.follow(live_hosted, user)
      assert ChannelLookups.count_live_followed_channels_that_are_hosting(user) == 0
      assert length(ChannelLookups.list_live_followed_channels(user)) == 2
    end

    test "a host who follows themselves should not see a channel they follow and are hosting duplicated on the following page",
         %{
           host: host,
           live_channel_hosted: live_hosted
         } do
      Glimesh.AccountFollows.follow(host, host)
      Glimesh.AccountFollows.follow(live_hosted, host)
      results = ChannelLookups.list_live_followed_channels_and_hosts(host)
      assert length(results) == 1
    end
  end
end
