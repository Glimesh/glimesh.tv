defmodule GlimeshWeb.UserRegistrationController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias GlimeshWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params, "h-captcha-response" => captcha_response}) do
    case Hcaptcha.verify(captcha_response) do
      {:ok, _} ->
        case Accounts.register_user(user_params) do
          {:ok, user} ->
            {:ok, _} =
              Accounts.deliver_user_confirmation_instructions(
                user,
                &Routes.user_confirmation_url(conn, :confirm, &1)
              )

            conn
            |> put_flash(:info, gettext("User created successfully."))
            |> UserAuth.log_in_user(user)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset)
        end

      {:error, _} ->
        conn
        |> put_flash(
          :error,
          gettext("Captcha validation failed, please try again.")
        )
        |> redirect(to: Routes.user_registration_path(conn, :new))
    end
  end

  def create(conn, %{"user" => _}) do
    conn
    |> put_flash(
      :error,
      gettext("Captcha validation failed, please make sure you have JavaScript enabled.")
    )
    |> redirect(to: Routes.user_registration_path(conn, :new))
  end
end
