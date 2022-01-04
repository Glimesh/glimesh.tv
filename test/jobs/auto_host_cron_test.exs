defmodule Glimesh.Jobs.AutoHostCronTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures

  alias Glimesh.Streams
  alias Glimesh.Streams.{Channel, ChannelHosts}
  alias Glimesh.Jobs.AutoHostCron

  defp create_host_task_data(_) do
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

    Ecto.Changeset.change(hosting_channel.channel)
    |> Ecto.Changeset.force_change(:status, "offline")
    |> Repo.update()

    good_target = streamer_fixture(%{}, %{allow_hosting: true})

    Channel.changeset(good_target.channel, %{status: "live"})
    |> Repo.update()

    {:ok, good_target_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: good_target.channel.id
      })

    bad_target_not_allow_hosting = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, bad_target_not_allow_hosting_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: bad_target_not_allow_hosting.channel.id
      })

    Ecto.Changeset.change(bad_target_not_allow_hosting.channel)
    |> Ecto.Changeset.force_change(:allow_hosting, false)
    |> Repo.update()

    hosting_target_no_longer_live = streamer_fixture(%{}, %{allow_hosting: true})

    {:ok, hosting_target_no_longer_live_channel_hosts} =
      ChannelHosts.add_new_host(hosting_channel, hosting_channel.channel, %ChannelHosts{
        hosting_channel_id: hosting_channel.channel.id,
        target_channel_id: hosting_target_no_longer_live.channel.id,
        status: "hosting",
        last_hosted_date: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    %{
      host: hosting_channel,
      good_target: good_target,
      good_target_channel_hosts: good_target_channel_hosts,
      bad_target_not_allow_hosting: bad_target_not_allow_hosting,
      bad_target_not_allow_hosting_channel_hosts: bad_target_not_allow_hosting_channel_hosts,
      hosting_target_no_longer_live: hosting_target_no_longer_live,
      hosting_target_no_longer_live_channel_hosts: hosting_target_no_longer_live_channel_hosts
    }
  end

  describe "Auto Host Job start hosting tasks" do
    setup :create_host_task_data

    test "Can Host a Channel", %{
      good_target_channel_hosts: good_target,
      host: host,
      hosting_target_no_longer_live_channel_hosts: bad_target
    } do
      assert :ok = AutoHostCron.perform([])

      assert Repo.get_by(ChannelHosts, %{id: good_target.id, status: "hosting"})
      assert Repo.get_by(ChannelHosts, %{id: bad_target.id, status: "ready"})

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where: ch.hosting_channel_id == ^host.channel.id and ch.status == "hosting"
               )
             ) == 1
    end

    test "Will un-host a channel whose hosting channel is now live", %{
      good_target_channel_hosts: good_target,
      host: host,
      hosting_target_no_longer_live_channel_hosts: bad_target
    } do
      assert :ok = AutoHostCron.perform([])

      assert Repo.get_by(ChannelHosts, %{id: good_target.id, status: "hosting"})
      assert Repo.get_by(ChannelHosts, %{id: bad_target.id, status: "ready"})

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where: ch.hosting_channel_id == ^host.channel.id and ch.status == "hosting"
               )
             ) == 1

      Ecto.Changeset.change(host.channel)
      |> Ecto.Changeset.force_change(:status, "live")
      |> Repo.update()

      assert :ok = AutoHostCron.perform([])

      assert Repo.get_by(ChannelHosts, %{id: good_target.id, status: "ready"})
      assert Repo.get_by(ChannelHosts, %{id: bad_target.id, status: "ready"})

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where: ch.hosting_channel_id == ^host.channel.id and ch.status == "hosting"
               )
             ) == 0
    end

    test "Will not host more than one target per host channel", %{
      good_target_channel_hosts: good_target,
      good_target: good_target_channel,
      host: host
    } do
      ChannelHosts.changeset(good_target, %{status: "hosting"})
      |> Repo.update()

      Channel.changeset(good_target_channel.channel, %{status: "live"})
      |> Repo.update()

      assert :ok = AutoHostCron.perform([])

      assert length(
               Repo.all(
                 from ch in ChannelHosts,
                   where: ch.hosting_channel_id == ^host.channel.id and ch.status == "hosting"
               )
             ) == 1
    end

    test "Will re-check errored targets", %{
      bad_target_not_allow_hosting: bad_target_channel,
      bad_target_not_allow_hosting_channel_hosts: bad_target
    } do
      assert :ok = AutoHostCron.perform([])

      assert length(
               Repo.all(
                 from ch in ChannelHosts, where: ch.id == ^bad_target.id and ch.status == "error"
               )
             ) == 1

      Ecto.Changeset.change(bad_target_channel.channel)
      |> Ecto.Changeset.force_change(:allow_hosting, true)
      |> Repo.update()

      assert :ok = AutoHostCron.perform([])

      assert length(
               Repo.all(
                 from ch in ChannelHosts, where: ch.id == ^bad_target.id and ch.status == "ready"
               )
             ) == 1
    end
  end
end
