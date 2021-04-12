defmodule GlimeshWeb.HomepageLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Homepage" do
    test "general text", %{conn: conn} do
      user_fixture()

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))

      assert html =~ "Join 1 others!"
    end

    test "does not show streams section if it's empty", %{conn: conn} do
      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))

      refute html =~ "Explore Live Streams"
    end

    test "shows streams section when there are channels", %{conn: conn} do
      Enum.each(1..6, fn _ -> Glimesh.HomepageTest.create_viable_mock_stream() end)
      assert Glimesh.Homepage.update_homepage() == :first_run

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))
      assert html =~ "Explore Live Streams"
    end
  end
end
