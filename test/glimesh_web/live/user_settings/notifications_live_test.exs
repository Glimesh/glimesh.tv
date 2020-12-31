defmodule GlimeshWeb.UserSettings.NotificationsLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Notifications Page" do
    setup :register_and_log_in_user

    test "shows a notifications page", %{conn: conn, user: user} do
      streamer = streamer_fixture()
      Glimesh.Streams.follow(streamer, user, true)

      {:ok, _, html} = live_isolated(conn, GlimeshWeb.NotificationsLive)

      assert html =~ "Notifications"
      assert html =~ "Newsletter Subscriptions"
      assert html =~ "Live Channel Notifications"
      assert html =~ streamer.displayname
    end

    test "can toggle notifications", %{conn: conn, user: user} do
      {:ok, view, _} = live_isolated(conn, GlimeshWeb.NotificationsLive)

      assert view
             |> element("form")
             |> render_change(%{
               "user" => %{
                 allow_glimesh_newsletter_emails: !user.allow_glimesh_newsletter_emails
               }
             }) =~ "Saved notification preferences."

      new_user = Glimesh.Accounts.get_user!(user.id)
      assert new_user.allow_glimesh_newsletter_emails !== user.allow_glimesh_newsletter_emails
    end

    test "can remove live channel subscription", %{conn: conn, user: user} do
      streamer = streamer_fixture()
      Glimesh.Streams.follow(streamer, user, true)
      {:ok, view, _} = live_isolated(conn, GlimeshWeb.NotificationsLive)

      html = view |> element("#streamer-#{streamer.id}") |> render_click()
      refute view |> element("#streamer-#{streamer.id}") |> has_element?()
      assert html =~ "Disabled live channel notifications for #{streamer.displayname}"
    end

    test "shows email logs", %{conn: conn, user: user} do
      Glimesh.Accounts.deliver_user_reset_password_instructions(
        user,
        fn _ -> "some-url" end
      )

      {:ok, _, html} = live_isolated(conn, GlimeshWeb.NotificationsLive)

      assert html =~ "Reset your password on Glimesh!"
    end
  end
end
