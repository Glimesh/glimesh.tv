defmodule GlimeshWeb.UserConfirmationController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      dgettext("profile", "If your e-mail is in our system and it has not been confirmed yet, ") <>
        dgettext("profile", "you will receive an e-mail with instructions shortly.")
    )
    |> redirect(to: "/")
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("profile", "Account confirmed successfully."))
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, dgettext("errors", "Confirmation link is invalid or it has expired."))
        |> redirect(to: "/")
    end
  end
end
