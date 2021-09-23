defmodule GlimeshWeb.UserRegistrationControllerTest do
  use GlimeshWeb.ConnCase, async: true

  import Glimesh.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h3>Register for our Alpha!</h3>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</button>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      username = unique_user_username()
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "h-captcha-response" => "valid_response",
          "user" => %{
            "username" => username,
            "email" => email,
            "password" => valid_user_password()
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ username
      assert response =~ "Settings"
      assert response =~ "Sign Out"
    end

    test "creates account and remembers preferences", %{conn: conn} do
      conn =
        conn
        |> init_test_session(site_theme: "light", locale: "de")

      username = unique_user_username()
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "h-captcha-response" => "valid_response",
          "user" => %{
            "username" => username,
            "email" => email,
            "password" => valid_user_password()
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ username
      assert response =~ "de ☀️"

      user = Glimesh.Accounts.get_by_username!(username)
      prefs = Glimesh.Accounts.get_user_preference!(user)

      assert prefs.site_theme == "light"
      assert prefs.locale == "de"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "h-captcha-response" => "valid_response",
          "user" => %{"email" => "with spaces", "password" => "short"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h3>Register for our Alpha!</h3>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 8 character(s)"
    end

    test "render errors if hcaptcha is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "h-captcha-response" => "invalid_response",
          "user" => %{"email" => "with spaces", "password" => "short"}
        })

      assert redirected_to(conn) == Routes.user_registration_path(conn, :create)

      assert get_flash(conn, :error) =~
               "Captcha validation failed, please try again."
    end

    test "render errors if hcaptcha does not load for some reason", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "short"}
        })

      assert redirected_to(conn) == Routes.user_registration_path(conn, :create)

      assert get_flash(conn, :error) =~
               "Captcha validation failed, please make sure you have JavaScript enabled."
    end

    test "does not pay attention to misc fields", %{conn: conn} do
      username = unique_user_username()
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "h-captcha-response" => "valid_response",
          "user" => %{
            "username" => username,
            "email" => email,
            "password" => valid_user_password(),
            "is_admin" => true,
            "gct_level" => 5
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      user = Glimesh.Accounts.get_user_by_email(email)
      refute user.is_admin
      assert is_nil(user.gct_level)

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ username
      assert response =~ "Settings"
      assert response =~ "Sign Out"
    end
  end
end
