defmodule Glimesh.Accounts.UserTest do
  use GlimeshWeb.ConnCase
  import Glimesh.AccountsFixtures
  alias Glimesh.Accounts.User
  alias Glimesh.Repo

  describe "profile_changeset/2" do
    test "it strips invalid username prepended with @" do
      attrs = %{social_instagram: "@glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_instagram) == "glimesh"
    end

    test "it strips invalid username prepended with spaces" do
      attrs = %{social_instagram: "           glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_instagram) == "glimesh"
    end

    test "it strips invalid username with a bunch of spaces" do
      attrs = %{social_instagram: "           glimesh          "}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_instagram) == "glimesh"
    end

    test "it strips invalid username with a bunch of slashes" do
      attrs = %{social_instagram: "////glimesh/////"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_instagram) == "glimesh"
    end

    test "it strips guilded.gg urls" do
      attrs = %{social_guilded: "https://guilded.gg/glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_guilded) == "glimesh"
    end

    test "it strips unsecured guilded.gg urls" do
      attrs = %{social_guilded: "http://guilded.gg/glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_guilded) == "glimesh"
    end

    test "it strips youtube username prepended with @" do
      attrs = %{social_youtube: "@glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_youtube) == "glimesh"
    end

    test "it strips secure discord invite links" do
      attrs = %{social_discord: "https://discord.gg/glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_discord) == "glimesh"
    end

    test "it strips insecure discord invite links" do
      attrs = %{social_discord: "http://discord.gg/glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_discord) == "glimesh"
    end

    test "it strips lazy discord invite links" do
      attrs = %{social_discord: "discord.gg/glimesh"}

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_discord) == "glimesh"
    end

    test "tests sanitizing many fields at once" do
      attrs = %{
        social_discord: "discord.gg/glimesh",
        social_youtube: "@glimesh",
        social_instagram: "@glimesh",
        social_guilded: "http://guilded.gg/glimesh"
      }

      changeset =
        user_fixture()
        |> User.profile_changeset(attrs)

      user = Repo.update!(changeset)

      assert changeset.valid?
      assert Map.get(user, :social_discord) == "glimesh"
      assert Map.get(user, :social_youtube) == "glimesh"
      assert Map.get(user, :social_instagram) == "glimesh"
      assert Map.get(user, :social_guilded) == "glimesh"
    end
  end
end
