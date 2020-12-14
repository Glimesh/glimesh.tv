defmodule Glimesh.Streams.Policy do
  @moduledoc """
  Glimesh Streams Policy
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  def authorize(:create_channel, %User{}, _nothing), do: true

  # Admins
  def authorize(:update_channel, %User{is_admin: true}, _channel), do: true
  def authorize(:delete_channel, %User{is_admin: true}, _channel), do: true

  def authorize(:show_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:create_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:update_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:delete_channel_moderator, %User{is_admin: true}, _channel), do: true

  # Streamers
  def authorize(:update_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:delete_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:show_channel_moderator, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:create_channel_moderator, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:update_channel_moderator, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:delete_channel_moderator, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(_, _, _), do: false
end
