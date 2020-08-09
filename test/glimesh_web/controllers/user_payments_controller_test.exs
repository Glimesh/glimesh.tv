defmodule GlimeshWeb.UserPaymentsControllerTest do
  use GlimeshWeb.ConnCase, async: true

  alias Glimesh.Accounts
  import Glimesh.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/payments" do
    # test "renders settings page", %{conn: conn} do
    #   conn = get(conn, Routes.user_payments_path(conn, :index))
    #   response = html_response(conn, 200)
    #   assert response =~ "<h2>Your Payment Portal</h2>"
    # end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_payments_path(conn, :index))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
