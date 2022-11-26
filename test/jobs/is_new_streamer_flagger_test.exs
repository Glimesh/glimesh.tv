defmodule Glimesh.Jobs.IsNewStreamerFlaggerTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures

  alias Glimesh.Streams
  alias Glimesh.Streams.{Channel}
  alias Glimesh.Jobs.IsNewStreamerFlagger

  describe "New Streamer Flagger Job tests" do
    test "Will flag streamers under seven days old" do
      streamer = streamer_fixture()
      create_eight_hour_stream(streamer.channel, -6)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == true
    end

    test "Will flag streamers over seven days old with less than five streams" do
      streamer = streamer_fixture()
      create_eight_hour_stream(streamer.channel, -9)
      create_eight_hour_stream(streamer.channel, -8)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == true
    end

    test "Will NOT flag streamers over seven days old with more than five streams" do
      streamer = streamer_fixture()
      create_eight_hour_stream(streamer.channel, -13)
      create_eight_hour_stream(streamer.channel, -12)
      create_eight_hour_stream(streamer.channel, -11)
      create_eight_hour_stream(streamer.channel, -10)
      create_eight_hour_stream(streamer.channel, -9)
      create_eight_hour_stream(streamer.channel, -8)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will clear flag when streamers no longer qualify" do
      streamer = streamer_fixture(%{}, %{is_new_streamer: true})
      create_eight_hour_stream(streamer.channel, -13)
      create_eight_hour_stream(streamer.channel, -12)
      create_eight_hour_stream(streamer.channel, -11)
      create_eight_hour_stream(streamer.channel, -10)
      create_eight_hour_stream(streamer.channel, -9)
      create_eight_hour_stream(streamer.channel, -8)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will NOT set flag when streamers have no streams" do
      streamer = streamer_fixture()

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will NOT set flag when streamers have disabled their channel" do
      streamer = streamer_fixture(%{}, %{inaccessible: true})
      create_eight_hour_stream(streamer.channel, -1)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will clear flag when streamers have disabled their channel" do
      streamer = streamer_fixture(%{}, %{inaccessible: true, is_new_streamer: true})
      create_eight_hour_stream(streamer.channel, -1)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will clear flag if streamers have more than 50 hours streamed" do
      streamer = streamer_fixture(%{}, %{is_new_streamer: true})
      create_a_stream(streamer.channel, -3)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end

    test "Will clear flag if streamers are within 7 days but have more then 50 hours streamed" do
      streamer = streamer_fixture()
      create_eight_hour_stream(streamer.channel, -5)
      create_eight_hour_stream(streamer.channel, -4)
      create_eight_hour_stream(streamer.channel, -3)
      create_eight_hour_stream(streamer.channel, -2)
      create_a_stream(streamer.channel, -1)

      assert :ok == IsNewStreamerFlagger.perform([])
      updated_channel = Glimesh.Repo.get(Channel, streamer.channel.id)
      assert updated_channel.is_new_streamer == false
    end
  end

  defp create_a_stream(%Channel{} = channel, num_days_ago, ended_at \\ get_utc_now()) do
    Streams.create_stream(channel, %{
      started_at:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * 24 * num_days_ago)
        |> NaiveDateTime.truncate(:second),
      ended_at: ended_at
    })
  end

  defp create_eight_hour_stream(%Channel{} = channel, num_days_ago) do
    ended_at =
      NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * 24 * num_days_ago + 28_800)
      |> NaiveDateTime.truncate(:second)

    create_a_stream(channel, num_days_ago, ended_at)
  end

  defp get_utc_now do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end
