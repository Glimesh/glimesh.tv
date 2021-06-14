defmodule Glimesh.HomepageTest do
  use Glimesh.DataCase

  import Glimesh.HomepageFixtures

  alias Glimesh.Homepage

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
