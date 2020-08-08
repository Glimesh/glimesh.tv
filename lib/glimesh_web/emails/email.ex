defmodule GlimeshWeb.Emails.Email do
  import Bamboo.Email

  def user_base_email() do
    new_email()
    |> from("support@glimesh.tv")
  end

  def user_confirmation_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Confirm your email with Glimesh!")
    |> text_body("""
     ==============================

     Hi #{user.displayname},

     You can confirm your account by visiting the url below:

     #{url}

     If you didn't create an account with us, please ignore this.

     ==============================
    """)
  end

  def user_reset_password_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Reset your password on Glimesh!")
    |> text_body("""
     ==============================

     Hi #{user.displayname},

     You can reset your password by visiting the url below:

     #{url}

     If you didn't request this change, please ignore this.

     ==============================
    """)
  end

  def user_update_email_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Change your email on Glimesh!")
    |> text_body("""
     ==============================

     Hi #{user.displayname},

     You can change your e-mail by visiting the url below:

     #{url}

     If you didn't request this change, please ignore this.

     ==============================
    """)
  end
end
