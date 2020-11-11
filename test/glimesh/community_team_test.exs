defmodule Glimesh.CommunityTeamTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.CommunityTeam

  describe "community team permission check functions" do

    test "access level returns correct title" do
      user = gct_fixture(%{gct_level: 50, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.access_level_to_title(user.gct_level) == "Admin"
    end

    test "can't edit user if no permission" do
      user = gct_fixture(%{gct_level: 20, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_edit_user(user) == false
    end

    test "can't edit channel if no permission" do
      user = gct_fixture(%{gct_level: 10, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_edit_channel(user) == false
    end

    test "can't edit user profile if no permission" do
      user = gct_fixture(%{gct_level: 10, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_edit_user_profile(user) == false
    end

    test "can't ban user if no permission" do
      user = gct_fixture(%{gct_level: 10, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_ban_user(user) == false
    end

    test "can't view audit log if no permission" do
      user = gct_fixture(%{gct_level: 20, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_view_audit_log(user) == false
    end

    test "can't view billing info if no permission" do
      user = gct_fixture(%{gct_level: 30, tfa_token: "Fake 2fa token"})

      assert CommunityTeam.can_view_billing_info(user) == false
    end
  end

  describe "access level checkers return the correct int" do

    test "global access level returns first integer" do
      test_int = 123456789

      assert CommunityTeam.get_global_access_level(test_int) == 1
    end

    test "billing access level returns second integer" do
      test_int = 123456789

      assert CommunityTeam.get_billing_override(test_int) == 2
    end
  end

end
