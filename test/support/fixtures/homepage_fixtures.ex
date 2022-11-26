defmodule Glimesh.HomepageFixtures do
  def create_viable_mock_stream(mock_time \\ nil, channel_attribs \\ %{}) do
    random_stream =
      Glimesh.AccountsFixtures.streamer_fixture(
        %{},
        Map.merge(channel_attribs, %{
          show_on_homepage: true
        })
      )

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
    random_stream = Glimesh.AccountsFixtures.streamer_fixture(%{}, %{})

    start_at = NaiveDateTime.add(end_at, -(60 * 60))

    %Glimesh.Streams.HomepageChannel{}
    |> Ecto.Changeset.change(%{
      slot_started_at: NaiveDateTime.truncate(start_at, :second),
      slot_ended_at: NaiveDateTime.truncate(end_at, :second)
    })
    |> Ecto.Changeset.put_assoc(:channel, random_stream.channel)
    |> Glimesh.Repo.insert!()
  end
end
