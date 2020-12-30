defmodule Glimesh.Streams.ChannelNotifier do
  @moduledoc false

  alias GlimeshWeb.Emails.Email
  alias GlimeshWeb.Emails.Mailer

  import Glimesh.Emails, only: [log_bamboo_delivery: 5]

  @doc """
  Deliver live channel notification.
  """
  def deliver_live_channel_notifications(users, channel, results \\ %{})

  def deliver_live_channel_notifications([user | users], channel, results) do
    email = Email.channel_live(user, channel.user, channel, channel.stream)

    result =
      cond do
        # One email per-streamer per-user per-hour for Live Channel Promotional
        Glimesh.Emails.email_sent_recently?(user, subject: email.subject) ->
          :debounced

        # Five emails per-user per-day for Live Channel Promotional
        Glimesh.Emails.count_emails_sent_recently(user, [type: "Live Channel Promotional"], 1440) >=
            5 ->
          :debounced

        true ->
          Mailer.deliver_later(email)
          |> log_bamboo_delivery(
            user,
            "Live Channel Promotional",
            "channel:live_channel_notification",
            email.subject
          )

          :sent
      end

    deliver_live_channel_notifications(users, channel, Map.put(results, user.email, result))
  end

  def deliver_live_channel_notifications([], _channel, results) do
    {:ok, results}
  end
end
