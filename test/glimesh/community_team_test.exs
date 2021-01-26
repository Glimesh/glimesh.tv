defmodule Glimesh.CommunityTeamTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.CommunityTeam

  describe "community team permission check functions" do
    test "access level returns correct title" do
      user = gct_fixture(%{gct_level: 5, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.access_level_to_title(user.gct_level) == "Admin"
    end

    test "can't edit user if no permission" do
      user = gct_fixture(%{gct_level: 2, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :edit_user, user, user_fixture()) == false
    end

    test "can't edit channel if no permission" do
      user = gct_fixture(%{gct_level: 1, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :edit_channel, user, user_fixture()) ==
               false
    end

    test "can't edit user profile if no permission" do
      user = gct_fixture(%{gct_level: 1, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :edit_user_profile, user, user_fixture()) ==
               false
    end

    test "can't ban user if no permission" do
      user = gct_fixture(%{gct_level: 1, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :can_ban, user, user_fixture()) == false
    end

    test "can't view audit log if no permission" do
      user = gct_fixture(%{gct_level: 2, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :view_audit_log, user, user_fixture()) ==
               false
    end

    test "can't view billing info if no permission" do
      user = gct_fixture(%{gct_level: 3, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :view_billing_info, user, user_fixture()) ==
               false
    end

    test "can't delete channel if no permission" do
      user = gct_fixture(%{gct_level: 2, tfa_token: "Fake 2fa token"})

      assert Bodyguard.permit?(Glimesh.CommunityTeam, :soft_delete_channel, user, user_fixture()) ==
               false
    end
  end
end
