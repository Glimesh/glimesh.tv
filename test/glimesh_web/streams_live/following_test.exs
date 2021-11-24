defmodule GlimeshWeb.StreamsLive.FollowingTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  defp create_channel(_) do
    streamer = streamer_fixture(%{}, %{})
    Glimesh.Streams.start_stream(streamer.channel)

    %{
      channel: streamer.channel,
      streamer: streamer
    }
  end

  describe "Following List" do
    setup [:register_and_log_in_user, :create_channel]

    test "lists no followed streams", %{
      conn: conn
    } do
      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, "following"))

      assert html =~ "Followed Streams"
      assert html =~ "None of the streams you follow are live"
      assert html =~ "All Followed Streamers"
      assert html =~ "You do not follow anyone who is offline"
    end

    test "lists some followed streams", %{
      conn: conn,
      streamer: streamer,
      channel: channel,
      user: user
    } do
      Glimesh.AccountFollows.follow(streamer, user)

      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, "following"))

      assert html =~ "Followed Streams"
      assert html =~ streamer.displayname
      assert html =~ channel.title
    end

    test "lists users that are offline", %{
      conn: conn,
      user: user
    } do
      streamer = streamer_fixture()
      Glimesh.AccountFollows.follow(streamer, user)

      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, "following"))

      assert html =~ "All Followed Streamers"
      assert html =~ streamer.displayname
    end

    test "lists channels hosted by followed streams", %{
      conn: conn,
      user: user,
      streamer: streamer,
      channel: channel
    } do
      Glimesh.AccountFollows.follow(streamer, user)
      live_streamer_not_followed = streamer_fixture(%{}, %{title: "Live being hosted"})
      Glimesh.Streams.start_stream(live_streamer_not_followed.channel)
      not_live_but_hosting_streamer = streamer_fixture(%{}, %{title: "Not live but hosting"})

      %Glimesh.Streams.ChannelHosts{
        hosting_channel_id: not_live_but_hosting_streamer.channel.id,
        target_channel_id: live_streamer_not_followed.channel.id,
        status: "hosting"
      }
      |> Glimesh.Repo.insert()

      Glimesh.AccountFollows.follow(not_live_but_hosting_streamer, user)

      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, "following"))

      assert html =~ "Live being hosted"
      assert html =~ live_streamer_not_followed.displayname
      assert html =~ channel.title
      assert html =~ streamer.displayname
      refute html =~ "Not live but hosting"
    end
  end
end
