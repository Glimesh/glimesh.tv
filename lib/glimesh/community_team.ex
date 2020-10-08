defmodule Glimesh.CommunityTeam do

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

end
