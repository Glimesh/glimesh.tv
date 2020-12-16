defmodule Glimesh.CommunityTeam.Policy do
  @moduledoc """

  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.CommunityTeam

  # Global Admin perms
  def authorize(:view_user, %User{is_admin: true}, _user), do: true
  def authorize(:edit_user_profile, %User{is_admin: true}, _user), do: true
  def authorize(:view_billing_info, %User{is_admin: true}, _user), do: true
  def authorize(:can_ban, %User{is_admin: true}, _user), do: true
  def authorize(:edit_channel, %User{is_admin: true}, _user), do: true
  def authorize(:view_audit_log, %User{is_admin: true}, _user), do: true

  # Global GCT perms
  def authorize(:view_user, %User{is_gct: true}, _user), do: true
  def authorize(:view_channel, %User{is_gct: true}, _user), do: true

  # GCT Admin perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:edit_user, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:view_billing_info, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 5}, _user), do: true
  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 5}, _user), do: true

  # GCT Manager perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:edit_user, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:view_billing_info, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 4}, _user), do: true
  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 4}, _user), do: true

  # GCT Team Lead perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 3}, _user), do: true
  def authorize(:edit_user, %User{is_gct: true, gct_level: 3}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 3}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 3}, _user), do: true
  def authorize(:view_audit_log, %User{is_gct: true, gct_level: 3}, _user), do: true

  # GCT Member perms
  def authorize(:edit_user_profile, %User{is_gct: true, gct_level: 2}, _user), do: true
  def authorize(:can_ban, %User{is_gct: true, gct_level: 2}, _user), do: true
  def authorize(:edit_channel, %User{is_gct: true, gct_level: 2}, _user), do: true


  def authorize(_, _, _), do: false

end
