defmodule GlimeshWeb.HomepageLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Glimesh.HomepageFixtures
  import Phoenix.LiveViewTest

  describe "Homepage" do
    setup do
      Supervisor.terminate_child(Glimesh.Supervisor, ConCache)
      Supervisor.restart_child(Glimesh.Supervisor, ConCache)
      :ok
    end

    test "general text", %{conn: conn} do
      user_fixture()

      {:ok, _, _html} = live(conn, Routes.homepage_path(conn, :index))

      # Commented out for now
      # assert html =~ "Join 1 others!"
    end

    test "does not show streams section if it's empty", %{conn: conn} do
      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))

      refute html =~ "Explore Live Streams"
    end

    test "shows video section when there are channels", %{conn: conn} do
      Enum.each(1..6, fn _ -> create_viable_mock_stream() end)
      assert Glimesh.Homepage.update_homepage() == :first_run

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))
      assert html =~ "<video "
    end

    test "shows streams section when there are channels", %{conn: conn} do
      streams =
        Enum.map(1..6, fn _ ->
          {:ok, stream} = create_viable_mock_stream()
          stream
        end)

      assert Glimesh.Homepage.update_homepage() == :first_run

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))
      assert html =~ hd(streams).title
    end

    test "shows live tags cloud when there are live channels", %{conn: conn} do
      subcat = subcategory_fixture()
      _stream = create_viable_mock_stream(nil, %{subcategory_id: subcat.id})

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))
      assert html =~ "subcat-badge-search"
    end

    test "does not show live tags cloud when there are no live channels with tags/subcategories",
         %{conn: conn} do
      _stream = create_viable_mock_stream()

      {:ok, _, html} = live(conn, Routes.homepage_path(conn, :index))
      refute html =~ "subcat-badge-search"
    end
  end
end
