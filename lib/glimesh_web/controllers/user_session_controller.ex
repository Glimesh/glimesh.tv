defmodule GlimeshWeb.UserSessionController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Tfa
  alias GlimeshWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      case user.is_banned do
        false ->
          if user.tfa_token do
            conn
            |> put_session(:tfa_user_id, user.id)
            |> render("tfa.html", error_message: nil)
          else
            UserAuth.log_in_user(conn, user, user_params)
          end

        true ->
          render(conn, "new.html",
            error_message:
              gettext(
                "User account is banned. Please contact support at %{email} for more information.",
                email: "support@glimesh.tv"
              )
          )
      end
    else
      render(conn, "new.html", error_message: gettext("Invalid e-mail or password"))
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
end
