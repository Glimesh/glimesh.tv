defmodule GlimeshWeb.UserLive.Components.FollowButtonTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.FollowButton

  defp create_streamer(_) do
    %{streamer: streamer_fixture()}
  end

  describe "follow button unauthed user" do
    setup :create_streamer

    test "shows a follow button that links to register", %{conn: conn, streamer: streamer} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => nil, "streamer" => streamer})

      assert html =~ "href=\"/users/register\""
      assert html =~ "Follow"
    end
  end

  describe "follow button authed user" do
    setup [:register_and_log_in_user, :create_streamer]

    # test "shows a disabled follow button for when the user is the streamer", %{
    #   conn: conn,
    #   streamer: streamer
    # } do
    #   {:ok, _, html} =
    #     live_isolated(conn, @component, session: %{"user" => streamer, "streamer" => streamer})

    #   assert html =~ "Follow"
    #   assert html =~ "btn btn-primary disabled follow-button"
    # end

    test "shows a follow button for another user", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, view, html} =
        live_isolated(conn, @component,
          id: "follow-button",
          session: %{"user" => user, "streamer" => streamer}
        )

      assert html =~ "Follow"
      assert html =~ "class=\"btn btn-primary follow-button btn-responsive\""

      new_button = view |> element("button", "Follow") |> render_click()
      assert new_button =~ "Unfollow"

      assert %Glimesh.AccountFollows.Follower{} =
               Glimesh.AccountFollows.get_following(streamer, user)
    end

    test "can unfollow after successfully following", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, _} = Glimesh.AccountFollows.follow(streamer, user)

      {:ok, view, _} =
        live_isolated(conn, @component,
          id: "follow-button",
          session: %{"user" => user, "streamer" => streamer}
        )

      new_button = view |> element("button", "Unfollow") |> render_click()
      assert new_button =~ "Follow"

      assert nil == Glimesh.AccountFollows.get_following(streamer, user)
    end

    test "can enable live notifications of a followed user", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, _} = Glimesh.AccountFollows.follow(streamer, user)

      {:ok, view, html} =
        live_isolated(conn, @component,
          id: "follow-button",
          session: %{"user" => user, "streamer" => streamer}
        )

      assert html =~ "far fa-bell"
      new_button = view |> element(".live-notifications-button") |> render_click()
      assert new_button =~ "fas fa-bell"

      following = Glimesh.AccountFollows.get_following(streamer, user)
      assert following.has_live_notifications == true
    end

    test "can disable live notifications of a followed user", %{
      conn: conn,
      user: user,
      streamer: streamer
    } do
      {:ok, _} = Glimesh.AccountFollows.follow(streamer, user, true)

      {:ok, view, html} =
        live_isolated(conn, @component,
          id: "follow-button",
          session: %{"user" => user, "streamer" => streamer}
        )

      assert html =~ "fas fa-bell"
      new_button = view |> element(".live-notifications-button") |> render_click()
      assert new_button =~ "far fa-bell"

      following = Glimesh.AccountFollows.get_following(streamer, user)
      assert following.has_live_notifications == false
    end
  end
end
