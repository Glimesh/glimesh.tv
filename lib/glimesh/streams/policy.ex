defmodule Glimesh.Streams.Policy do
  @moduledoc """
  Glimesh Streams Policy
  """

  @behaviour Bodyguard.Policy

  import GlimeshWeb.Gettext

  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Streams.Channel

  def authorize(:create_channel, %User{}), do: true

  # Admins
  def authorize(:update_channel, %User{is_admin: true}, _channel), do: true
  def authorize(:delete_channel, %User{is_admin: true}, _channel), do: true

  # Streamers
  def authorize(:update_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:delete_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(_, _, _), do: false
end
