defmodule GlimeshWeb.QuickPreferenceControllerTest do
  use GlimeshWeb.ConnCase

  describe "quick preferences as anonymous user" do
    test "has sane preferences", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "en 🌘"
      assert html_response(conn, 200) =~ "<html lang=\"en\" data-theme=\"dark\">"
    end

    test "updates preferences", %{conn: conn} do
      conn =
        post(conn, ~p"/quick_preferences",
          user_preference: %{
            "locale" => "de",
            "site_theme" => "light",
            "user_return_to" => ~p"/"
          }
        )

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Preferences updated successfully."

      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "de ☀️"
      assert html_response(conn, 200) =~ "<html lang=\"de\" data-theme=\"light\">"
    end
  end

  describe "quick preferences as logged in user" do
    setup :register_and_log_in_user

    test "has sane preferences", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "en 🌘"
      assert html_response(conn, 200) =~ "<html lang=\"en\" data-theme=\"dark\">"
    end

    test "updates preferences", %{conn: conn} do
      conn =
        post(conn, ~p"/quick_preferences",
          user_preference: %{
            "locale" => "de",
            "site_theme" => "light",
            "user_return_to" => ~p"/"
          }
        )

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Preferences updated successfully."

      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "de ☀️"
      assert html_response(conn, 200) =~ "<html lang=\"de\" data-theme=\"light\">"
    end
  end
end
