defmodule GlimeshWeb.UserAuthorizedAppsControllerTest do
  use GlimeshWeb.ConnCase

  setup :register_and_log_in_user

  describe "GET /users/settings/applications" do
    test "returns a list of authorized applications", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/authorizations")
      assert html_response(conn, 200) =~ "Authorized Applications"
    end
  end
end
