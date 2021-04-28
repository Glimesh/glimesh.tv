defmodule GlimeshWeb.UserPaymentsControllerTest do
  use GlimeshWeb.ConnCase, async: true
  import Glimesh.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/payments" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_payments_path(conn, :index))
      response = html_response(conn, 200)
      assert response =~ "Your Payment Portal</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_payments_path(conn, :index))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "#394 hide receipt links on failed" do
    test "does not show Receipt link when payment is failed", %{conn: conn} do
      user = user_fixture()

      res =
        conn
        |> Phoenix.Controller.put_view(GlimeshWeb.UserPaymentsView)
        |> Phoenix.Controller.render(
          "index.html",
          page_title: "Your Payment Portal",
          user: user,
          can_payments: true,
          can_receive_payments: true,
          incoming: 0,
          outgoing: 0,
          stripe_countries: [],
          platform_subscription: nil,
          subscriptions: [],
          default_payment_changeset: nil,
          has_payment_method: nil,
          stripe_dashboard_url: nil,
          payment_history: [
            %{
              created: DateTime.utc_now(),
              description: "Success",
              amount: 10_000,
              receipt_url: "http://doesntmatter",
              status: "succeeded"
            },
            %{
              created: DateTime.utc_now(),
              description: "Failed",
              amount: 10_000,
              receipt_url: "http://doesntmatter",
              status: "failed"
            }
          ]
        )

      body = res.resp_body
      assert Regex.run(~r/Receipt/, body) |> Enum.count() == 1
    end
  end
end
