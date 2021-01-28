defmodule GlimeshWeb.UserSessionController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Tfa
  alias GlimeshWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => %{"login" => login, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_login_and_password(login, password) do
      attempt_login(conn, user, user_params)
    else
      render(conn, "new.html", error_message: gettext("Invalid e-mail / username or password"))
    end
  end

  def tfa(conn, %{"user" => %{"tfa" => tfa} = user_params}) do
    if user = Accounts.get_user!(get_session(conn, :tfa_user_id)) do
      if Tfa.validate_pin(tfa, user.tfa_token) do
        UserAuth.log_in_user(conn, user, user_params)
      else
        render(conn, "new.html",
          error_message:
            gettext("Invalid 2FA code, if you need help please email %{email}",
              email: "support@glimesh.tv"
            )
        )
      end
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end

  # Attempt a login if the user isn't banned
  def attempt_login(conn, %{is_banned: false} = user, user_params) do
    if user.tfa_token do
      conn
      |> put_session(:tfa_user_id, user.id)
      |> render("tfa.html", error_message: nil)
    else
      UserAuth.log_in_user(conn, user, user_params)
    end
  end

  # Attempt a login on a banned user
  def attempt_login(conn, %{is_banned: true}, _user_params) do
    render(conn, "new.html",
      error_message:
        gettext(
          "User account is banned. Please contact support at %{email} for more information.",
          email: "support@glimesh.tv"
        )
    )
  end
end
