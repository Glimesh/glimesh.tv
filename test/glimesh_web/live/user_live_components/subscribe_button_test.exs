defmodule GlimeshWeb.UserLive.Components.SubscribeButtonTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.SubscribeButton

  defp create_streamer(_) do
    %{streamer: streamer_fixture(%{can_payments: true, can_receive_payments: true})}
  end

  describe "subscription button unauthed user" do
    setup :create_streamer

    test "shows a subscription button that links to register", %{conn: conn, streamer: streamer} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => nil, "streamer" => streamer})

      assert html =~ "href=\"/users/register\""
      assert html =~ "Subscribe"
    end
  end

  describe "subscription button authed user" do
    setup [:register_and_log_in_user, :create_streamer]

    test "shows a disabled subscription button for user without can_payments", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => user, "streamer" => streamer})

      assert html =~ "Subscribe"
      assert html =~ "btn btn-secondary btn-responsive disabled"
    end

    test "shows a disabled subscription button for when the user is the streamer", %{
      conn: conn,
      streamer: streamer
    } do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => streamer, "streamer" => streamer})

      assert html =~ "Subscribe"
      assert html =~ "btn btn-secondary btn-responsive disabled"
    end

    test "shows a subscription button for user with can_payments", %{
      conn: conn,
      streamer: streamer
    } do
      user = user_fixture(%{can_payments: true})

      {:ok, view, html} =
        live_isolated(conn, @component,
          id: "subscribe-button",
          session: %{"user" => user, "streamer" => streamer}
        )

      assert html =~ "Subscribe"
      assert html =~ "class=\"btn btn-secondary btn-responsive\""

      modal = view |> element("button", "Subscribe") |> render_click()
      assert modal =~ "$5.00 / monthly"
    end
  end
end
