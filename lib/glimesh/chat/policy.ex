defmodule Glimesh.Chat.Policy do
  @moduledoc """
  Glimesh Chat Policy

  :create_chat_message -> Should allow admins, streamers, and users who are not banned.

  :ban -> Should allow admins, streamers, and moderators with permission.
  :short_timeout -> Should allow admins, streamers, and moderators with permission.
  :long_timeout -> Should allow admins, streamers, and moderators with permission.
  :unban -> Should allow admins, streamers, and moderators with permission.

  """

  @behaviour Bodyguard.Policy

  import GlimeshWeb.Gettext

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Streams.Channel

  def authorize(:create_chat_message, %User{is_admin: true}, _channel), do: true

  def authorize(:create_chat_message, %User{id: user_id} = user, %Channel{
        user_id: channel_user_id
      })
      when user_id == channel_user_id do
    if Accounts.is_user_banned?(user) do
      {:error, gettext("You are banned from Glimesh.")}
    else
      true
    end
  end

  def authorize(:create_chat_message, %User{} = user, %Channel{} = channel) do
    account_age = NaiveDateTime.diff(NaiveDateTime.utc_now(), user.inserted_at, :second)

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
      Accounts.is_user_banned?(user) ->
        {:error, gettext("You are banned from Glimesh.")}

      # Require all chatters to have a verified email
      channel.require_confirmed_email and is_nil(user.confirmed_at) ->
        {:error, gettext("You must confirm your email address before chatting.")}

      # Require a minimum account age before following
      minimum_account_age_not_met?(channel, account_age) ->
        time_left = trunc((channel.minimum_account_age * 60 * 60 - account_age) / 60)

        {:error,
         gettext("You must wait %{time_left} more minutes to chat.", time_left: time_left)}

      true ->
        true
    end
  end

  def authorize(:create_tenor_message, %User{id: user_id} = user, %Channel{
        user_id: channel_user_id
      })
      when user_id == channel_user_id do
    cond do
      Accounts.is_user_banned?(user) ->
        {:error, gettext("You are banned from Glimesh.")}

      # Reaction gifs must be enabled site wide
      !Channel.allow_reaction_gifs_site_wide?() ->
        {:error, gettext("Reaction gifs are not enabled site-wide.")}

      true ->
        true
    end
  end

  def authorize(:create_tenor_message, %User{} = user, %Channel{} = channel) do
    account_age = NaiveDateTime.diff(NaiveDateTime.utc_now(), user.inserted_at, :second)

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
      Accounts.is_user_banned?(user) ->
        {:error, gettext("You are banned from Glimesh.")}

      # Require all chatters to have a verified email
      channel.require_confirmed_email and is_nil(user.confirmed_at) ->
        {:error, gettext("You must confirm your email address before chatting.")}

      # Require a minimum account age before following
      minimum_account_age_not_met?(channel, account_age) ->
        time_left = trunc((channel.minimum_account_age * 60 * 60 - account_age) / 60)

        {:error,
         gettext("You must wait %{time_left} more minutes to chat.", time_left: time_left)}

      # Reaction gifs must be enabled on the channel and site wide
      Channel.allow_reaction_gifs?(channel) == false ->
        {:error, gettext("Reaction gifs are not enabled either on this channel or site-wide.")}

      true ->
        true
    end
  end

  # Admins
  def authorize(:ban, %User{is_admin: true}, _channel), do: true
  def authorize(:unban, %User{is_admin: true}, _channel), do: true
  def authorize(:short_timeout, %User{is_admin: true}, _channel), do: true
  def authorize(:long_timeout, %User{is_admin: true}, _channel), do: true
  def authorize(:delete, %User{is_admin: true}, _channel), do: true

  def authorize(:create_tenor_message, %User{is_admin: true}, _channel) do
    # Reaction gifs must be enabled site wide
    if Channel.allow_reaction_gifs_site_wide?() == false do
      {:error, gettext("Reaction gifs are not enabled site-wide.")}
    else
      true
    end
  end

  # GCT
  def authorize(:ban, %User{is_gct: true}, _channel), do: true
  def authorize(:unban, %User{is_gct: true}, _channel), do: true
  def authorize(:short_timeout, %User{is_gct: true}, _channel), do: true
  def authorize(:long_timeout, %User{is_gct: true}, _channel), do: true
  def authorize(:delete, %User{is_gct: true}, _channel), do: true

  def authorize(:create_tenor_message, %User{is_gct: true}, _channel) do
    # Reaction gifs must be enabled site wide
    if Channel.allow_reaction_gifs_site_wide?() == false do
      {:error, gettext("Reaction gifs are not enabled site-wide.")}
    else
      true
    end
  end

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

  def authorize(:delete, %User{id: user_id}, %Channel{user_id: channel_user_id})
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

  def authorize(:delete, %User{} = user, %Channel{} = channel),
    do: Chat.can_moderate?(:can_delete, channel, user)

  def authorize(_, _, _), do: false

  defp minimum_account_age_not_met?(%Channel{} = channel, account_age) do
    channel.minimum_account_age > 0 and account_age < channel.minimum_account_age * 60 * 60
  end
end
