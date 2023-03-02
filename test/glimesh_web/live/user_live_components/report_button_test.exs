defmodule GlimeshWeb.UserLive.Components.ReportButtonTest do
  use GlimeshWeb.ConnCase
  use Bamboo.Test, shared: true

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.ReportButton

  defp create_streamer(_) do
    %{streamer: streamer_fixture()}
  end

  describe "report button unauthed user" do
    setup :create_streamer

    test "shows a report button that does nothing?", %{conn: conn, streamer: streamer} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => nil, "streamer" => streamer})

      assert String.contains?(html, "Report User") == false
    end
  end

  describe "report button authed user" do
    setup [:register_and_log_in_user, :create_streamer]

    test "shows a report button for another user", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => user, "streamer" => streamer})

      assert html =~ "Report User"
    end

    test "can report another user", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      admin = admin_fixture()

      {:ok, view, _} =
        live_isolated(conn, @component, session: %{"user" => user, "streamer" => streamer})

      button = view |> element("a", "Report User") |> render_click()
      # Should render a modal at this point
      assert button =~ "Submit Report"

      assert render_submit(view, "save", %{
               "report_reason" => "other",
               "location" => "some location",
               "notes" => "Some notes"
             }) =~
               "Report submitted, thank you!"

      email =
        GlimeshWeb.Emails.Email.user_report_alert(
          admin,
          user,
          streamer,
          "other",
          "some location",
          "Some notes",
          ""
        )

      assert_delivered_email(email)
    end
  end
end
