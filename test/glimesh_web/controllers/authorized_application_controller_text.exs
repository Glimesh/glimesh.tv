defmodule GlimeshWeb.AuthorizedApplicationControllerTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings/applications" do
    test "returns a list of authorized applications", %{conn: conn} do
      conn = get(conn, Routes.authorized_application_path(conn, :index))
      assert html_response(conn, 200) =~ "Authorized Applications"
    end
  end
end
