defmodule GlimeshWeb.EventsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Events Live View Tests" do
    test "shows a default empty events", %{conn: conn} do
      {:ok, _, html} = live(conn, Routes.events_path(conn, :index))

      assert html =~ "Featured Events"
      assert html =~ "Event Calendar"
      assert html =~ "Having an event?"
    end

    test "shows a featured event", %{conn: conn} do
      Glimesh.EventsTeam.create_event(%Glimesh.EventsTeam.Event{
        type: "",
        start_date: "",
        end_date: "",
        label: "",
        description: "",
        featured: "",
        channel: ""
      })

      {:ok, _, html} = live(conn, Routes.events_path(conn, :index))

      assert html =~ "Featured Events"
      assert html =~ "Event Calendar"
      assert html =~ "Having an event?"
    end

    test "does not show a non-featured event", %{conn: conn} do
      {:ok, _, html} = live(conn, Routes.events_path(conn, :index))

      assert html =~ "Featured Events"
      assert html =~ "Event Calendar"
      assert html =~ "Having an event?"
    end
  end
end
