defmodule Glimesh.Streams.ChannelNotifier do
  @moduledoc false

  alias GlimeshWeb.Emails.Email
  alias GlimeshWeb.Emails.Mailer

  import Glimesh.Emails, only: [log_bamboo_delivery: 5]

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_live_channel_notification(users, channel) do
    for user <- users do
      email = Email.channel_live(user, channel)

      Mailer.deliver_later(email)
      |> log_bamboo_delivery(
        user,
        "Live Channel Promotional",
        "channel:live_channel_notification",
        email.subject
      )
    end

    {:ok, %{}}
  end
end
