defmodule Glimesh.Accounts.UserNotifier do
  alias GlimeshWeb.Emails.Email
  alias GlimeshWeb.Emails.Mailer

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    email = Email.user_confirmation_instructions(user, url)

    Mailer.deliver_later(email)

    {:ok, %{to: email.to, body: email.text_body}}
  end

  @doc """
  Deliver instructions to reset password account.
  """
  def deliver_reset_password_instructions(user, url) do
    email = Email.user_reset_password_instructions(user, url)

    Mailer.deliver_later(email)

    {:ok, %{to: email.to, body: email.text_body}}
  end

  @doc """
  Deliver instructions to update your e-mail.
  """
  def deliver_update_email_instructions(user, url) do
    email = Email.user_update_email_instructions(user, url)

    Mailer.deliver_later(email)

    {:ok, %{to: email.to, body: email.text_body}}
  end
end
