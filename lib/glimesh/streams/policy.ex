defmodule Glimesh.Streams.Policy do
  @moduledoc """
  Glimesh Streams Policy
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  def authorize(:create_channel, %User{}, _nothing), do: true

  def authorize(
        :start_stream,
        %User{can_stream: can_stream, confirmed_at: confirmed_at},
        _nothing
      )
      when can_stream and not is_nil(confirmed_at),
      do: true

  # Admins
  def authorize(:update_channel, %User{is_admin: true}, _channel), do: true
  def authorize(:delete_channel, %User{is_admin: true}, _channel), do: true
  def authorize(:dismiss_homepage_opt_in_notification, %User{is_admin: true}, _channel), do: true

  def authorize(:show_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:create_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:update_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:delete_channel_moderator, %User{is_admin: true}, _channel), do: true
  def authorize(:edit_channel_title_and_tags, %User{is_admin: true}, _channel), do: true

  def authorize(:delete_hosting_target, %User{is_admin: true}, _channel), do: true

  # GCT
  def authorize(:update_channel, %User{is_gct: true}, _channel), do: true
  def authorize(:delete_channel, %User{is_gct: true}, _channel), do: true
  def authorize(:dismiss_homepage_opt_in_notification, %User{is_gct: true}, _channel), do: true

  def authorize(:show_channel_moderator, %User{is_gct: true}, _channel), do: true
  def authorize(:create_channel_moderator, %User{is_gct: true}, _channel), do: true
  def authorize(:update_channel_moderator, %User{is_gct: true}, _channel), do: true
  def authorize(:delete_channel_moderator, %User{is_gct: true}, _channel), do: true
  def authorize(:edit_channel_title_and_tags, %User{is_gct: true}, _channel), do: true

  # Editors
  def authorize(:edit_channel_title_and_tags, %User{id: user_id}, [
        %Channel{user_id: channel_user_id},
        is_editor
      ])
      when user_id == channel_user_id or is_editor,
      do: true

  # Streamers
  def authorize(:update_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:delete_channel, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:dismiss_homepage_opt_in_notification, %User{id: user_id}, %Channel{
        user_id: channel_user_id
      })
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

  def authorize(:delete_hosting_target, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(:add_hosting_target, %User{id: user_id}, %Channel{user_id: channel_user_id})
      when user_id == channel_user_id,
      do: true

  def authorize(_, _, _), do: false
end
