defmodule GlimeshWeb.ShortLinkControllerTest do
  use GlimeshWeb.ConnCase

  describe "short links" do
    test "redirects to the event form", %{conn: conn} do
      conn = get(conn, Routes.short_link_path(conn, :event_form))
      assert redirected_to(conn) == "https://forms.gle/6VpqMzc6i1XomaP86"
    end
  end
end
