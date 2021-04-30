defmodule GlimeshWeb.GctLive.ManageEmotesTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Emotes Management" do
    # test "lists some users", %{conn: conn} do
    #   user = user_fixture()

    #   {:ok, _, html} = live(conn, Routes.user_index_path(conn, :index))

    #   assert html =~ "Our Users"
    #   assert html =~ user.displayname
    # end

    test "can upload emotes", %{conn: conn} do
      # Ensures the user we test for is not on the first page
      Enum.each(1..20, fn _ -> user_fixture() end)
      user = user_fixture()

      {:ok, view, _} = live(conn, Routes.user_index_path(conn, :index))

      assert render_submit(view, :search, %{q: user.username}) =~ user.displayname
    end
  end
end
