defmodule GlimeshWeb.UserSettings.ProfileSettingsLiveTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Glimesh.Accounts
  alias Glimesh.Accounts.{User, UserSocial}
  alias Glimesh.Repo

  describe "Social links" do
    setup :register_and_log_in_user

    test "disconnecting twitter account removes account name from profile", %{
      conn: conn,
      user: user
    } do
      {:ok, updated_user} = Accounts.update_user_profile(user, %{social_twitter: "testuser123"})

      {:ok, _social} =
        UserSocial.changeset(%UserSocial{user: updated_user}, %{
          platform: "twitter",
          identifier: "test",
          username: "testuser123"
        })
        |> Repo.insert()

      user_changeset = User.profile_changeset(updated_user, %{})

      {:ok, _view, html} =
        live_isolated(conn, GlimeshWeb.UserSettings.Components.ProfileSettingsLive,
          session: %{
            "user" => updated_user,
            "profile_changeset" => user_changeset,
            "route" => Routes.user_settings_path(conn, :update_profile)
          }
        )

      assert html =~ "btn-twitter-disconnect"
      assert html =~ "@ testuser123"

      conn = delete(conn, Routes.user_social_path(conn, :disconnect, "twitter"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :profile)
      conn = recycle(conn)

      updated_user = Repo.get(User, user.id)
      user_changeset = User.profile_changeset(updated_user, %{})

      {:ok, _view, html} =
        live_isolated(conn, GlimeshWeb.UserSettings.Components.ProfileSettingsLive,
          session: %{
            "user" => updated_user,
            "profile_changeset" => user_changeset,
            "route" => Routes.user_settings_path(conn, :update_profile)
          }
        )

      assert html =~ "btn-twitter-connect"
      assert html =~ "Connect Twitter Account"
      refute html =~ "@testuser123"
    end
  end
end
