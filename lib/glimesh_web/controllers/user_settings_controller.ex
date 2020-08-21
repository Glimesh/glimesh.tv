defmodule GlimeshWeb.UserSettingsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias GlimeshWeb.UserAuth

  plug :put_layout, "user-sidebar.html"

  plug :assign_profile_changesets

  def profile(conn, _params) do
    render(conn, "profile.html")
  end

  def stream(conn, _params) do
    render(conn, "stream.html")
  end

  def settings(conn, _params) do
    render(conn, "settings.html")
  end

  def update_profile(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, gettext("Profile updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :profile))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "profile.html", profile_changeset: changeset)
    end
  end

  defp assign_profile_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:user, user)
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
  end
end
