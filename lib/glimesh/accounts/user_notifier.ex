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

  @spec deliver_reset_password_instructions(atom | %{displayname: any, email: any}, any) ::
          {:ok, %{body: nil | binary, to: any}}
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

  @doc """
  Send a user report alert to an admin
  """
  def deliver_user_report_alert(reporting_user, reported_user, reason, notes) do
    admins = Glimesh.Accounts.list_admins()

    for admin <- admins do
      email = Email.user_report_alert(admin, reporting_user, reported_user, reason, notes)

      Mailer.deliver_later(email)
    end

    {:ok, %{}}
  end
end
