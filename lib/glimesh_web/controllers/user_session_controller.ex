defmodule GlimeshWeb.UserSessionController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Tfa
  alias GlimeshWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_login_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def tfa(conn, %{"user" => %{"tfa" => tfa} = user_params}) do
    if user = Accounts.get_user!(get_session(conn, :tfa_user_id)) do
      if Tfa.validate_pin(tfa, user.tfa_token) do
        params = Map.put(user_params, "remember_me", get_session(conn, :tfa_remember_me))
        UserAuth.log_in_user(conn, user, params)
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
      |> put_session(:tfa_remember_me, Map.get(user_params, "remember_me", false))
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
