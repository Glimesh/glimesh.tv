defmodule GlimeshWeb.ShortLinkControllerTest do
  use GlimeshWeb.ConnCase

  describe "short links" do
    test "redirects to the event form", %{conn: conn} do
      conn = get(conn, ~p"/s/event-form")
      assert redirected_to(conn) == "https://forms.gle/6VpqMzc6i1XomaP86"
    end
  end
end
