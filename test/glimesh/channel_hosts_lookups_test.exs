defmodule Glimesh.ChannelHostsLookupsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  import Glimesh.StreamsFixtures
  alias Glimesh.Streams
  alias Glimesh.Streams.ChannelHosts
  alias Glimesh.ChannelHostsLookups

  defp create_auto_hosting_data(_) do
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

    # -------------------------------------------------------------

    good_target = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, good_target_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: good_target.channel.id
      })

    # -------------------------------------------------------------

    bad_target_not_allow_hosting = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, bad_target_not_allow_hosting_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: bad_target_not_allow_hosting.channel.id
      })

    Ecto.Changeset.change(bad_target_not_allow_hosting.channel)
    |> Ecto.Changeset.force_change(:allow_hosting, false)
    |> Repo.update()

    # -------------------------------------------------------------

    bad_target_banned_host = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, bad_target_banned_host_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: bad_target_banned_host.channel.id
      })

    channel_banned_user_fixture(bad_target_banned_host.channel, hosting_channel)
    # -------------------------------------------------------------

    bad_target_inaccessible = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, bad_target_inaccessible_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: bad_target_inaccessible.channel.id
      })

    Ecto.Changeset.change(bad_target_inaccessible.channel)
    |> Ecto.Changeset.force_change(:inaccessible, true)
    |> Repo.update()

    # -------------------------------------------------------------

    bad_target_user_banned = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, bad_target_user_banned_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: bad_target_user_banned.channel.id
      })

    bad_target_user_banned = change_user_banned_status(bad_target_user_banned, true)
    # -------------------------------------------------------------

    hosting_target_still_live = streamer_fixture(%{}, %{allow_hosting: true})
    change_channel_status(hosting_target_still_live.channel, "live")

    {:ok, hosting_target_still_live_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: hosting_target_still_live.channel.id,
        status: "hosting"
      })

    # -------------------------------------------------------------

    hosting_target_no_longer_live = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, hosting_target_no_longer_live_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: hosting_target_no_longer_live.channel.id,
        status: "hosting"
      })

    # -------------------------------------------------------------

    bad_hosting_channel_banned_by_target = streamer_fixture(%{}, %{})

    {:ok, bad_target_host_banned_in_target_chat_channel_hosts} =
      Ecto.Changeset.change(%ChannelHosts{
        hosting_channel_id: bad_hosting_channel_banned_by_target.channel.id,
        target_channel_id: good_target.channel.id
      })
      |> Repo.insert()

    Ecto.Changeset.change(%Glimesh.Streams.ChannelBan{
      user: bad_hosting_channel_banned_by_target,
      channel: good_target.channel,
      expires_at: nil
    })
    |> Repo.insert()

    # -------------------------------------------------------------

    bad_hosting_channel_platform_banned = streamer_fixture(%{is_banned: true}, %{})

    {:ok, bad_hosting_channel_platform_banned_channel_hosts} =
      Ecto.Changeset.change(%ChannelHosts{
        hosting_channel_id: bad_hosting_channel_platform_banned.channel.id,
        target_channel_id: good_target.channel.id
      })
      |> Repo.insert()

    # -------------------------------------------------------------

    bad_hosting_channel_inaccessible = streamer_fixture(%{}, %{inaccessible: true})

    {:ok, bad_hosting_channel_inaccessible_channel_hosts} =
      Ecto.Changeset.change(%ChannelHosts{
        hosting_channel_id: bad_hosting_channel_inaccessible.channel.id,
        target_channel_id: good_target.channel.id
      })
      |> Repo.insert()

    # -------------------------------------------------------------

    bad_hosting_channel_cant_stream = streamer_fixture(%{}, %{})

    Ecto.Changeset.change(bad_hosting_channel_cant_stream)
    |> Ecto.Changeset.force_change(:can_stream, false)
    |> Repo.update()

    {:ok, bad_hosting_channel_cant_stream_channel_hosts} =
      Ecto.Changeset.change(%ChannelHosts{
        hosting_channel_id: bad_hosting_channel_cant_stream.channel.id,
        target_channel_id: good_target.channel.id
      })
      |> Repo.insert()

    # -------------------------------------------------------------

    %{
      host: hosting_channel,
      good_target: good_target,
      good_target_channel_hosts: good_target_channel_hosts,
      bad_target_not_allow_hosting: bad_target_not_allow_hosting,
      bad_target_not_allow_hosting_channel_hosts: bad_target_not_allow_hosting_channel_hosts,
      bad_target_banned_host: bad_target_banned_host,
      bad_target_banned_host_channel_hosts: bad_target_banned_host_channel_hosts,
      bad_target_inaccessible: bad_target_inaccessible,
      bad_target_inaccessible_channel_hosts: bad_target_inaccessible_channel_hosts,
      bad_target_user_banned: bad_target_user_banned,
      bad_target_user_banned_channel_hosts: bad_target_user_banned_channel_hosts,
      hosting_target_still_live: hosting_target_still_live,
      hosting_target_still_live_channel_hosts: hosting_target_still_live_channel_hosts,
      hosting_target_no_longer_live: hosting_target_no_longer_live,
      hosting_target_no_longer_live_channel_hosts: hosting_target_no_longer_live_channel_hosts,
      bad_hosting_channel_banned_by_target: bad_hosting_channel_banned_by_target,
      bad_target_host_banned_in_target_chat_channel_hosts:
        bad_target_host_banned_in_target_chat_channel_hosts,
      bad_hosting_channel_platform_banned: bad_hosting_channel_platform_banned,
      bad_hosting_channel_platform_banned_channel_hosts:
        bad_hosting_channel_platform_banned_channel_hosts,
      bad_hosting_channel_inaccessible: bad_hosting_channel_inaccessible,
      bad_hosting_channel_inaccessible_channel_hosts:
        bad_hosting_channel_inaccessible_channel_hosts,
      bad_hosting_channel_cant_stream: bad_hosting_channel_cant_stream,
      bad_hosting_channel_cant_stream_channel_hosts: bad_hosting_channel_cant_stream_channel_hosts
    }
  end

  describe "Auto Host Job Cleanup Tasks" do
    setup :create_auto_hosting_data

    test "Unhost no longer live channels",
         %{
           hosting_target_no_longer_live_channel_hosts:
             hosting_target_no_longer_live_channel_hosts,
           hosting_target_still_live_channel_hosts: hosting_target_still_live_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{
               id: hosting_target_no_longer_live_channel_hosts.id,
               status: "hosting"
             })

      assert Repo.get_by(ChannelHosts, %{
               id: hosting_target_still_live_channel_hosts.id,
               status: "hosting"
             })

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.unhost_channels_not_live()
      assert num_rows == 1

      refute Repo.get_by(ChannelHosts, %{
               id: hosting_target_no_longer_live_channel_hosts.id,
               status: "hosting"
             })

      assert Repo.get_by(ChannelHosts, %{
               id: hosting_target_no_longer_live_channel_hosts.id,
               status: "ready"
             })

      assert Repo.get_by(ChannelHosts, %{
               id: hosting_target_still_live_channel_hosts.id,
               status: "hosting"
             })
    end

    test "Invalidate a previously valid host target if it no longer allows hosting",
         %{
           bad_target_not_allow_hosting_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a previously invalid host target if it now allows hosting",
         %{
           bad_target_not_allow_hosting_channel_hosts: bad_channel_hosts,
           bad_target_not_allow_hosting: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      Ecto.Changeset.change(bad_channel.channel)
      |> Ecto.Changeset.force_change(:allow_hosting, true)
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()
      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a previously valid host target if the host is banned in the target chat",
         %{
           bad_target_host_banned_in_target_chat_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a previously invalid host target if the host is no longer banned in the target chat",
         %{
           bad_target_host_banned_in_target_chat_channel_hosts: bad_channel_hosts,
           bad_hosting_channel_banned_by_target: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      Repo.get_by(Glimesh.Streams.ChannelBan, %{
        user_id: bad_channel.id,
        channel_id: bad_channel_hosts.target_channel_id
      })
      |> Repo.delete()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()
      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a previously valid host target if the target is now inaccessible",
         %{
           bad_target_inaccessible_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a previously invalid host target if the target is now accessible",
         %{
           bad_target_inaccessible_channel_hosts: bad_channel_hosts,
           bad_target_inaccessible: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel.channel)
      |> Ecto.Changeset.force_change(:inaccessible, false)
      |> Repo.update()

      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()

      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a previously valid host target if the target is banned",
         %{
           bad_target_user_banned_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a previously invalid host target if the target is no longer banned",
         %{
           bad_target_user_banned_channel_hosts: bad_channel_hosts,
           bad_target_user_banned: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel)
      |> Ecto.Changeset.force_change(:is_banned, false)
      |> Repo.update()

      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()

      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a host if the host is platform banned",
         %{
           bad_hosting_channel_platform_banned_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a host if the host is no longer platform banned",
         %{
           bad_hosting_channel_platform_banned_channel_hosts: bad_channel_hosts,
           bad_hosting_channel_platform_banned: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel)
      |> Ecto.Changeset.force_change(:is_banned, false)
      |> Repo.update()

      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()

      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a host if the host channel is inaccessible",
         %{
           bad_hosting_channel_inaccessible_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a host if the host channel is accessible again",
         %{
           bad_hosting_channel_inaccessible_channel_hosts: bad_channel_hosts,
           bad_hosting_channel_inaccessible: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel.channel)
      |> Ecto.Changeset.force_change(:inaccessible, false)
      |> Repo.update()

      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()

      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Invalidate a host if the host channel can't stream",
         %{
           bad_hosting_channel_cant_stream_channel_hosts: bad_channel_hosts,
           good_target_channel_hosts: good_channel_hosts
         } do
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows >= 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "re-validate a host if the host channel can stream again",
         %{
           bad_hosting_channel_cant_stream_channel_hosts: bad_channel_hosts,
           bad_hosting_channel_cant_stream: bad_channel,
           good_target_channel_hosts: good_channel_hosts
         } do
      Ecto.Changeset.change(bad_channel)
      |> Ecto.Changeset.force_change(:can_stream, true)
      |> Repo.update()

      Ecto.Changeset.change(bad_channel_hosts)
      |> Ecto.Changeset.force_change(:status, "error")
      |> Repo.update()

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()

      assert num_rows == 1
      refute Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "error"})
      assert Repo.get_by(ChannelHosts, %{id: bad_channel_hosts.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: good_channel_hosts.id, status: "ready"})
    end

    test "Test cleanup functions in aggregate", %{
      good_target_channel_hosts: good,
      bad_hosting_channel_banned_by_target: bad_host,
      bad_hosting_channel_platform_banned: bad_host_platform_banned,
      bad_hosting_channel_inaccessible: bad_host_inaccessible,
      bad_hosting_channel_cant_stream: bad_host_cant_stream,
      hosting_target_still_live_channel_hosts: live
    } do
      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.recheck_error_status_channels()
      assert num_rows == 0

      {:ok, %{:num_rows => num_rows}} = ChannelHostsLookups.unhost_channels_not_live()
      assert num_rows == 1

      {:ok, %{:num_rows => num_rows}} =
        ChannelHostsLookups.invalidate_hosting_channels_where_necessary()

      assert num_rows == 8

      assert Repo.get_by(ChannelHosts, %{id: good.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: live.id, status: "hosting"})

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where:
                     ch.hosting_channel_id == ^good.hosting_channel_id and ch.status == "error"
               )
             ) == 4

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where: ch.hosting_channel_id == ^bad_host.channel.id and ch.status == "error"
               )
             ) == 1

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where:
                     ch.hosting_channel_id == ^bad_host_platform_banned.channel.id and
                       ch.status == "error"
               )
             ) == 1

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where:
                     ch.hosting_channel_id == ^bad_host_inaccessible.channel.id and
                       ch.status == "error"
               )
             ) == 1

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where:
                     ch.hosting_channel_id == ^bad_host_cant_stream.channel.id and
                       ch.status == "error"
               )
             ) == 1

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where:
                     ch.hosting_channel_id == ^good.hosting_channel_id and ch.status == "ready"
               )
             ) == 2
    end
  end
end
