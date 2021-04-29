defmodule GlimeshWeb.UserLive.Components.SocialButtonsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  alias Glimesh.Accounts

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
        Accounts.update_user_profile(streamer, %{
          "social_discord" => "glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
      assert String.contains?(html, "Twitter") == false
    end

    test "correctly strips @ symbols", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_discord" => "@glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
    end

    test "correctly strips multiple @ symbols", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_discord" => "@@@@@glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
    end

    test "correctly strips slashes", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_discord" => "/////glimesh/////"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
    end

    test "correctly trims spaces", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_discord" => "        glimesh      "
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://discord.gg/glimesh"
    end

    test "correctly trims guilded urls", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_guilded" => "https://guilded.gg/glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://guilded.gg/glimesh"
    end

    test "correctly shows guilded urls using username", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_guilded" => "glimesh"
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      assert html =~ "https://guilded.gg/glimesh"
    end

    test "correctly handles nil values", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Accounts.update_user_profile(streamer, %{
          "social_guilded" => nil
        })

      {:ok, _, html} = live_isolated(conn, @component, session: %{"user_id" => streamer.id})

      refute html =~ "guilded"
    end
  end
end
