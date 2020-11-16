defmodule Glimesh.Chat.Policy do
  @moduledoc """
  Glimesh Chat Policy


  """

  @behaviour Bodyguard.Policy

  import GlimeshWeb.Gettext

  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Streams.Channel

  def authorize(:create_chat_message, %User{is_admin: true}, _channel), do: true

  def authorize(:create_chat_message, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:create_chat_message, %User{} = user, %Channel{} = channel) do
    cond do
      # Specific Channel Ban
      expiry = Chat.is_banned_until(channel, user) ->
        if expiry == :infinity do
          {:error, gettext("You are permanently banned from this channel.")}
        else
          seconds = NaiveDateTime.diff(expiry, NaiveDateTime.utc_now(), :second)

          {:error,
           gettext("You are banned from this channel for %{minutes} more minutes.",
             minutes: round(Float.ceil(seconds / 60))
           )}
        end

      # Global Account Ban
      Glimesh.Accounts.is_user_banned?(user) ->
        {:error, gettext("You are banned from Glimesh.")}

      true ->
        true
    end
  end

  # Admins
  def authorize(:ban, %User{is_admin: true}, _channel), do: true
  def authorize(:unban, %User{is_admin: true}, _channel), do: true
  def authorize(:short_timeout, %User{is_admin: true}, _channel), do: true
  def authorize(:long_timeout, %User{is_admin: true}, _channel), do: true

  # Channel Owners
  def authorize(:ban, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:unban, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:short_timeout, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:long_timeout, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  # Moderators
  def authorize(:ban, %User{} = user, %Channel{} = channel),
    do: Chat.can_moderate?(:can_ban, channel, user)

  def authorize(:unban, %User{} = user, %Channel{} = channel),
    do: Chat.can_moderate?(:can_unban, channel, user)

  def authorize(:short_timeout, %User{} = user, %Channel{} = channel),
    do: Chat.can_moderate?(:can_short_timeout, channel, user)

  def authorize(:long_timeout, %User{} = user, %Channel{} = channel),
    do: Chat.can_moderate?(:can_long_timeout, channel, user)

  def authorize(_, _, _), do: false
end
