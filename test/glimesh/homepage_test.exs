defmodule Glimesh.HomepageTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Homepage

  def create_viable_mock_stream(mock_time \\ nil) do
    random_stream =
      streamer_fixture(%{}, %{
        show_on_homepage: true
      })

    start_time =
      if mock_time, do: mock_time, else: NaiveDateTime.add(NaiveDateTime.utc_now(), -(16 * 60))

    # Create an old stream that lasts 10 hours
    {:ok, stream} = Glimesh.Streams.start_stream(random_stream.channel)
    {:ok, stream} = Glimesh.Streams.end_stream(stream)

    {:ok, _} =
      Glimesh.Streams.update_stream(stream, %{
        ended_at: NaiveDateTime.add(NaiveDateTime.utc_now(), 11 * 60 * 60)
      })

    {:ok, stream} = Glimesh.Streams.start_stream(random_stream.channel)

    {:ok, _} =
      Glimesh.Streams.update_stream(stream, %{
        started_at: start_time
      })
  end

  def fake_homepage_channel_record(end_at \\ NaiveDateTime.utc_now()) do
    random_stream = streamer_fixture(%{}, %{})

    start_at = NaiveDateTime.add(end_at, -(60 * 60))

    %Glimesh.Streams.HomepageChannel{}
    |> Ecto.Changeset.change(%{
      slot_started_at: NaiveDateTime.truncate(start_at, :second),
      slot_ended_at: NaiveDateTime.truncate(end_at, :second)
    })
    |> Ecto.Changeset.put_assoc(:channel, random_stream.channel)
    |> Glimesh.Repo.insert!()
  end

  describe "Homepage" do
    test "get_homepage/0 returns nothing" do
      assert length(Homepage.get_homepage()) == 0
    end

    test "get_homepage/0 some streams when update_homepage has run" do
      Enum.each(1..6, fn _ -> create_viable_mock_stream() end)

      assert Homepage.update_homepage() == :first_run

      assert length(Homepage.get_homepage()) == 6
    end

    test "update_homepage/0 only runs once unless it's time" do
      Enum.each(1..6, fn _ -> create_viable_mock_stream() end)

      assert Homepage.update_homepage() == :first_run
      assert Homepage.update_homepage() == :not_time

      assert length(Homepage.get_homepage()) == 6
    end

    # No idea how to write this test..
    # test "update_homepage/0 runs correctly at 14 minutes left" do
    #   # Ends 14 minutes from now
    #   fake_homepage_channel_record(NaiveDateTime.add(NaiveDateTime.utc_now(), 14 * 60))

    #   Enum.each(1..6, fn _ -> create_viable_mock_stream() end)

    #   assert Homepage.update_homepage() == :on_time
    #   assert Homepage.update_homepage() == :not_time

    #   assert length(Homepage.get_homepage()) == 6
    # end

    test "update_homepage/0 runs correctly past time" do
      # Ended two hours ago
      fake_homepage_channel_record(NaiveDateTime.add(NaiveDateTime.utc_now(), -(2 * 60 * 60)))

      Enum.each(1..6, fn _ -> create_viable_mock_stream() end)

      assert Homepage.update_homepage() == :late
      assert Homepage.update_homepage() == :not_time

      assert length(Homepage.get_homepage()) == 6
    end
  end
end
