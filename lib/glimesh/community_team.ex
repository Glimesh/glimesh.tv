defmodule Glimesh.CommunityTeam do
  @moduledoc """
  The Community Team context :)
  """

  def access_level_to_title(level) do
    case level do
      5 -> "Admin"
      4 -> "Manager"
      3 -> "Team Lead"
      2 -> "Team Member"
      1 -> "Trial Member"
      _ -> "None"
    end
  end

  def can_edit_user(user) do
    if user.gct_level >= 3, do: true, else: false
  end

  def can_edit_user_profile(user) do
    if user.gct_level >= 2, do: true, else: false
  end

  def can_ban_user(user) do
    if user.gct_level >= 4, do: true, else: false
  end

  def can_delete_user(user) do
    if user.gct_level >= 5, do: true, else: false
  end
end
