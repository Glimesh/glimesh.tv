defmodule GlimeshWeb.UserConfirmationController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User

  def new(conn, _params) do
    case conn.assigns.current_user do
      %User{confirmed_at: confirmed_at} when not is_nil(confirmed_at) ->
        conn
        |> put_flash(:info, gettext("Your account's email is already confirmed."))
        |> redirect(to: "/")

      %User{email: email} ->
        render(conn, "new.html", existing_email: email)

      nil ->
        render(conn, "new.html", existing_email: nil)
    end
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        fn token -> url(~p"/users/confirm/#{token}") end
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      gettext("If your e-mail is in our system and it has not been confirmed yet, ") <>
        gettext("you will receive an e-mail with instructions shortly.")
    )
    |> redirect(to: "/")
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Account confirmed successfully."))
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(
          :error,
          gettext("Confirmation link is invalid or it has expired.")
        )
        |> redirect(to: "/")
    end
  end
end
