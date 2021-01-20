defmodule GlimeshWeb.Emails.Email do
  use Bamboo.Phoenix, view: GlimeshWeb.EmailView

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.Stream
  alias GlimeshWeb.Router.Helpers, as: Routes

  import Bamboo.Email

  def user_base_email do
    new_email()
    |> put_html_layout({GlimeshWeb.LayoutView, "email.html"})
    |> put_text_layout({GlimeshWeb.LayoutView, "email.text"})
    |> from("Glimesh <support@glimesh.tv>")
  end

  def user_confirmation_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Confirm your email with Glimesh!")
    |> assign(:user, user)
    |> assign(:url, url)
    |> render(:user_confirmation)
  end

  def user_reset_password_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Reset your password on Glimesh!")
    |> assign(:user, user)
    |> assign(:url, url)
    |> render(:user_reset_password)
  end

  def user_update_email_instructions(user, url) do
    user_base_email()
    |> to(user.email)
    |> subject("Change your email on Glimesh!")
    |> assign(:user, user)
    |> assign(:url, url)
    |> render(:user_update_email)
  end

  def user_report_alert(admin, reporting_user, reported_user, reason, notes) do
    user_base_email()
    |> to(admin.email)
    |> subject("User Alert Report for #{reported_user.displayname}!")
    |> text_body("""
     ==============================

     Hi #{admin.displayname},

     A new user alert has come in!

     Reported User:
      Username: #{reported_user.username}
      Reason: #{reason}
      Notes: #{notes}

     Reported By:
      Username: #{reporting_user.username}

     ==============================
    """)
  end

  def channel_live(%User{} = user, %User{} = streamer, %Channel{} = channel, %Stream{} = stream) do
    user_base_email()
    |> to(user.email)
    |> subject("#{streamer.displayname} is live on Glimesh!")
    |> assign(:user, user)
    |> assign(:stream_thumbnail, Glimesh.StreamThumbnail.url({stream.thumbnail, stream}))
    |> assign(:stream_title, channel.title)
    |> assign(
      :stream_link,
      Routes.user_stream_url(GlimeshWeb.Endpoint, :index, streamer.username)
    )
    |> assign(:unsubscribe_link, Routes.user_settings_url(GlimeshWeb.Endpoint, :notifications))
    |> assign(:streamer_name, streamer.displayname)
    |> render(:channel_live)
  end
end
