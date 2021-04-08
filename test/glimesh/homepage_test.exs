defmodule Glimesh.HomepageTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Homepage

  def create_viable_mock_stream() do
    random_stream =
      streamer_fixture(%{}, %{
        show_on_homepage: true
      })

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
        started_at: NaiveDateTime.add(NaiveDateTime.utc_now(), -(16 * 60))
      })
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
  end
end
