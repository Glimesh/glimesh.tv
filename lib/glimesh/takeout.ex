defmodule Glimesh.Takeout do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel

  def export_user(%User{} = user) do
    user = user |> Repo.preload(:channel)

    user
    |> zip()
  end

  defp export_functions,
    do: [
      user: &profile_info/1,
      channel: &channel_info/1,
      payments: &payments/1,
      payouts: &payouts/1
    ]

  defp zip(%User{} = user) do
    dir = System.tmp_dir!()
    zip_folder = Path.join(dir, "#{user.username}-takeout")
    File.mkdir(zip_folder)

    Enum.each(export_functions(), fn {name, func} ->
      out =
        func.(user)
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()

      file_path = Path.join(zip_folder, "#{name}.json")
      File.write(file_path, out)
    end)

    # Emotes
    emotes = list_all_emotes_for_user(user)
    emote_folder = Path.join(zip_folder, "emotes")
    File.mkdir(emote_folder)

    Enum.each(emotes, fn emote ->
      full_url = Glimesh.Emotes.full_url(emote)
      file_type = Glimesh.Emotes.file_type(emote)
      body = local_or_remote_bytes(full_url)

      File.write(Path.join(emote_folder, "#{emote.emote}.#{file_type}"), body)
    end)

    # Zip!
    files =
      Path.join(zip_folder, "*")
      |> Path.wildcard()
      |> Enum.map(fn p ->
        String.replace(p, "#{zip_folder}/", "")
      end)
      |> Enum.map(&String.to_charlist/1)

    zip_result = :zip.create("#{user.username}-takeout.zip", files, [:memory, cwd: zip_folder])

    File.rm_rf(zip_folder)

    zip_result
  end

  defp profile_info(%User{} = user) do
    full_user = Repo.preload(user, [:socials, :user_preference])

    chat_messages = Repo.all(Glimesh.Chat.list_some_chat_messages_for_user(user, 10_000))

    safe_messages = map_chat_messages(chat_messages)

    %{
      user: user,
      socials: full_user.socials,
      preferences: full_user.user_preference,
      chat_messages: safe_messages
    }
  end

  defp channel_info(%User{} = user) do
    channel = Glimesh.ChannelLookups.get_channel_for_user(user)

    if is_nil(channel) do
      %{}
    else
      chat_messages = Glimesh.Chat.list_chat_messages(channel, 10_000)

      safe_messages = map_chat_messages(chat_messages)
      safe_emotes = map_emotes(list_all_emotes_for_user(user))

      %{
        channel: channel,
        chat_messages: safe_messages,
        emotes: safe_emotes
      }
    end
  end

  defp payments(%User{} = user) do
    payments =
      Repo.all(
        from p in Glimesh.Payments.Payable,
          where: p.user_id == ^user.id,
          order_by: [desc: p.streamer_payout_at],
          preload: [:streamer]
      )
      |> Enum.map(fn payable ->
        %{
          channel: payable.streamer.username,
          type: payable.type,
          external_source: payable.external_source,
          external_reference: payable.external_reference,
          status: payable.status,
          total_amount: payable.total_amount,
          external_fees: payable.external_fees,
          our_fees: payable.our_fees,
          withholding_amount: payable.withholding_amount,
          payout_amount: payable.payout_amount,
          user_paid_at: payable.user_paid_at,
          streamer_payout_at: payable.streamer_payout_at,
          streamer_payout_amount: payable.streamer_payout_amount,
          stripe_transfer_id: payable.stripe_transfer_id,
          inserted_at: payable.inserted_at,
          updated_at: payable.updated_at
        }
      end)

    %{
      payments: payments
    }
  end

  defp payouts(%User{} = user) do
    payouts =
      Repo.all(
        from p in Glimesh.Payments.Payable,
          where: p.streamer_id == ^user.id,
          order_by: [desc: p.streamer_payout_at],
          preload: [:user]
      )
      |> Enum.map(fn payable ->
        %{
          user: payable.user.username,
          type: payable.type,
          external_source: payable.external_source,
          external_reference: payable.external_reference,
          status: payable.status,
          total_amount: payable.total_amount,
          external_fees: payable.external_fees,
          our_fees: payable.our_fees,
          withholding_amount: payable.withholding_amount,
          payout_amount: payable.payout_amount,
          user_paid_at: payable.user_paid_at,
          streamer_payout_at: payable.streamer_payout_at,
          streamer_payout_amount: payable.streamer_payout_amount,
          stripe_transfer_id: payable.stripe_transfer_id,
          inserted_at: payable.inserted_at,
          updated_at: payable.updated_at
        }
      end)

    %{
      payouts: payouts
    }
  end

  defp map_emotes(emotes) do
    Enum.map(emotes, fn emote ->
      %{
        emote: emote.emote,
        animated: emote.animated,
        svg: emote.svg,
        approved_at: emote.approved_at,
        approved_for_global_use: emote.approved_for_global_use,
        rejected_at: emote.rejected_at,
        rejected_reason: emote.rejected_reason,
        require_channel_sub: emote.require_channel_sub,
        allow_global_usage: emote.allow_global_usage,
        emote_display_off: emote.emote_display_off
      }
    end)
  end

  defp map_chat_messages(chat_messages) do
    Enum.map(chat_messages, fn message ->
      %{
        username: message.user.username,
        channel: message.channel.streamer.username,
        message: message.message,
        tokens:
          Enum.map(message.tokens, fn token ->
            %{
              type: token.type,
              text: token.text,
              url: token.url,
              src: token.src
            }
          end),
        is_visible: message.is_visible,
        is_followed_message: message.is_followed_message,
        is_subscription_message: message.is_subscription_message,
        inserted_at: message.inserted_at
      }
    end)
  end

  defp list_all_emotes_for_user(%User{} = user) do
    if is_nil(user.channel) do
      []
    else
      Repo.all(
        from(e in Glimesh.Emotes.Emote,
          left_join: c in Glimesh.Streams.Channel,
          on: c.id == e.channel_id,
          where: e.channel_id == ^user.channel.id,
          distinct: e.id,
          order_by: e.emote
        )
      )
    end
  end

  defp local_or_remote_bytes("http" <> _ = url) do
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url)
    body
  end

  defp local_or_remote_bytes(path) do
    path =
      if String.contains?(path, "?") do
        String.split(path, "?") |> hd
      else
        path
      end

    {:ok, bytes} = File.read("./#{path}")
    bytes
  end
end
