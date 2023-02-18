defmodule GlimeshWeb.UserSocialControllerTest do
  use GlimeshWeb.ConnCase, async: true

  setup :register_and_log_in_user

  describe "GET /users/social/twitter/twitter_connect" do
    test "redirects correctly", %{conn: conn} do
      auth_url =
        conn
        |> bypass_through()
        |> get("/")
        |> Glimesh.Socials.Twitter.authorize_url()

      if is_nil(auth_url) do
        conn =
          conn
          |> get(Routes.user_social_path(conn, :twitter_connect))

        assert redirected_to(conn) == Routes.user_settings_path(conn, :profile)
        assert get_flash(conn, :error) =~ "There was a problem connecting your twitter account."
      else
        conn =
          conn
          |> get(Routes.user_social_path(conn, :twitter_connect))

        assert redirected_to(conn) =~ "twitter.com"
      end
    end
  end
end
