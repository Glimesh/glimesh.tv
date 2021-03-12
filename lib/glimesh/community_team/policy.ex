defmodule Glimesh.CommunityTeam.Policy do
  @moduledoc false

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User

  # Global Admin perms
  def authorize(:view_user, %User{is_admin: true}, _user), do: true
  def authorize(:edit_user_profile, %User{is_admin: true}, _user), do: true
  def authorize(:view_billing_info, %User{is_admin: true}, _user), do: true
  def authorize(:can_ban, %User{is_admin: true}, _user), do: true
  def authorize(:edit_channel, %User{is_admin: true}, _user), do: true
  def authorize(:view_audit_log, %User{is_admin: true}, _user), do: true
  def authorize(:soft_delete_channel, %User{is_admin: true}, _user), do: true

  # Global GCT perms
  def authorize(:view_user, %User{is_gct: true}, _user), do: true
  def authorize(:view_channel, %User{is_gct: true}, _user), do: true
  def authorize(:view_chat_logs, %User{is_gct: true}, _user), do: true

  # GCT Admin perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:edit_user, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:view_billing_info, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:soft_delete_channel, %User{is_gct: true, gct_level: 5}, _user), do: true

  # GCT Manager perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:edit_user, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:view_billing_info, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:soft_delete_channel, %User{is_gct: true, gct_level: 4}, _user), do: true

  # GCT Team Lead perms
  def authorize(:soft_delete_channel, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:edit_user, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:view_billing_info, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:can_ban, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:edit_channel, %User{is_gct: true, gct_level: 3} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 3}, _user), do: true

  # GCT Member perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 2} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:edit_user, %User{is_gct: true, gct_level: 2} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:can_ban, %User{is_gct: true, gct_level: 2} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(:edit_channel, %User{is_gct: true, gct_level: 2} = current_user, user) do
    if is_self?(current_user, user) || is_user_higher_level?(current_user, user),
      do: false,
      else: true
  end

  def authorize(_, _, _), do: false

  defp is_self?(current_user, user) do
    if current_user == user, do: true, else: false
  end

  defp is_user_higher_level?(current_user, user) do
    user_level = if user.gct_level, do: user.gct_level, else: 0
    if current_user.gct_level < user_level, do: true, else: false
  end
end
