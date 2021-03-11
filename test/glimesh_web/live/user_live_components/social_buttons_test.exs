defmodule GlimeshWeb.UserLive.Components.SocialButtonsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.SocialButtons

  defp create_channel(_) do
    streamer = streamer_fixture()

    %{
      channel: streamer.channel,
      streamer: streamer
    }
  end

  describe "social buttons" do
    setup :create_channel

    test "render correctly", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Glimesh.Accounts.update_user_profile(streamer, %{
          "social_discord" => "glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
      assert String.contains?(html, "Twitter") == false
    end
  end
end
