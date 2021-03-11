defmodule Glimesh.SocialsTest do
  use Glimesh.DataCase

  alias Glimesh.Accounts.Profile
  alias Glimesh.Socials
  import Glimesh.AccountsFixtures

  describe "socials" do
    alias Glimesh.Accounts.UserSocial

    def social_fixture(user) do
      Socials.connect_user_social(user, "twitter", "1234", "clone1018")
    end

    test "get_social/2 gets a single social" do
      user = user_fixture()
      social_fixture(user)

      found_social = Socials.get_social(user, "twitter")
      assert %UserSocial{} = found_social
      assert found_social.identifier == "1234"
    end

    test "get_social/2 returns nil on nothing" do
      user = user_fixture()

      assert is_nil(Socials.get_social(user, "twitter"))
    end

    test "connected?/2 returns truthy values" do
      user = user_fixture()
      social_fixture(user)

      assert Socials.connected?(user, "twitter")
      refute Socials.connected?(user, "facebook")
    end

    test "connect_user_social/4 creates a new user social" do
      user = user_fixture()

      assert {:ok, %UserSocial{} = social} =
               Socials.connect_user_social(user, "facebook", "1234", "testuser")

      assert social.identifier == "1234"
    end

    test "connect_user_social/4 doens't duplicate socials" do
      user = user_fixture()

      assert {:ok, %UserSocial{}} =
               Socials.connect_user_social(user, "facebook", "1234", "testuser")

      assert {:error, %Ecto.Changeset{}} =
               Socials.connect_user_social(user, "facebook", "1234", "testuser")
    end

    test "disconnect_user_social/2 deletes a social connection" do
      user = user_fixture()
      social_fixture(user)

      assert {:ok, _deleted} = Socials.disconnect_user_social(user, "twitter")
      assert is_nil(Socials.get_social(user, "twitter"))
    end

    test "works with twitter share button" do
      user = user_fixture()
      social_fixture(user)
      fresh_user = Glimesh.Accounts.get_user!(user.id)

      assert Profile.viewer_share_text(fresh_user, "https://example.com/") =~
               URI.encode_www_form("Just followed @clone1018")
    end
  end

  describe "old social features" do
    test "viewer share text works with old social_twitter" do
      user = user_fixture()

      {:ok, fresh_user} =
        Glimesh.Accounts.update_user_profile(user, %{
          social_twitter: "clone1018"
        })

      assert Profile.viewer_share_text(fresh_user, "https://example.com/") =~
               URI.encode_www_form("Just followed @clone1018")
    end
  end
end
