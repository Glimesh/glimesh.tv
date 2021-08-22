defmodule GlimeshWeb.GctLive.ButtonArrayTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  describe "Button array on user lookup" do
    setup [:register_and_log_in_gct_user]

    test "can remove 2fa", %{conn: conn, user: user} do
      lookup_user = user_fixture(%{tfa_token: "Wow look at this token"})

      {:ok, view, html} =
        live_isolated(conn, GlimeshWeb.GctLive.Components.ButtonArray,
          session: %{"admin" => user, "user" => lookup_user}
        )

      assert html =~ "Remove 2FA"

      {:ok, conn} =
        view
        |> element("a", "Remove 2FA")
        |> render_click()
        |> follow_redirect(conn)

      refute conn.resp_body =~ "Remove 2FA"
    end
  end
end
