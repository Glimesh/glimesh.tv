defmodule GlimeshWeb.UserLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Users List" do
    test "lists some users", %{conn: conn} do
      user = user_fixture()

      {:ok, _, html} = live(conn, ~p"/users")

      assert html =~ "Our Users"
      assert html =~ user.displayname
    end

    test "can search for users", %{conn: conn} do
      # Ensures the user we test for is not on the first page
      Enum.each(1..20, fn _ -> user_fixture() end)
      user = user_fixture()

      {:ok, view, _} = live(conn, ~p"/users")

      assert render_submit(view, :search, %{q: user.username}) =~ user.displayname
    end
  end
end
