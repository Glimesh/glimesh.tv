defmodule GlimeshWeb.LayoutViewTest do
  use GlimeshWeb.ConnCase, async: true

  import Glimesh.AccountsFixtures

  defp create_live_stream(_) do
    streamer = streamer_fixture(%{}, %{})
    Glimesh.Streams.start_stream(streamer.channel)

    %{
      channel: streamer.channel,
      streamer: streamer
    }
  end

  describe "Following/Hosted count for logged in user" do
    setup [:register_and_log_in_user, :create_live_stream]

    test "No following or hosted count if not following anyone", %{user: user} do
      refute GlimeshWeb.LayoutView.count_live_following_channels(%{assigns: %{current_user: user}})
    end

    test "Following count when following people", %{streamer: streamer, user: user} do
      Glimesh.AccountFollows.follow(streamer, user)

      assert GlimeshWeb.LayoutView.count_live_following_channels(%{assigns: %{current_user: user}}) ==
               1
    end

    test "Hosting count when following people who are hosting others", %{
      channel: channel,
      user: user
    } do
      followed_hosting_others = streamer_fixture(%{}, %{})

      %Glimesh.Streams.ChannelHosts{
        hosting_channel_id: followed_hosting_others.channel.id,
        target_channel_id: channel.id,
        status: "hosting"
      }
      |> Glimesh.Repo.insert()

      Glimesh.AccountFollows.follow(followed_hosting_others, user)

      refute GlimeshWeb.LayoutView.count_live_following_channels(%{assigns: %{current_user: user}})

      assert GlimeshWeb.LayoutView.count_live_hosted_channels(%{assigns: %{current_user: user}}) ==
               1
    end
  end

  describe "No following/hosted counts for non-logged in users" do
    setup [:create_live_stream]

    test "No following count" do
      refute GlimeshWeb.LayoutView.count_live_following_channels(%{})
    end

    test "No hosted count" do
      refute GlimeshWeb.LayoutView.count_live_hosted_channels(%{})
    end
  end
end
