defmodule GlimeshWeb.UserSettingsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Streams
  alias GlimeshWeb.UserAuth

  plug :put_layout, "user-sidebar.html"

  plug :assign_profile_changesets
  plug :assign_channel_changesets

  def profile(conn, _params) do
    twitter_auth_url = Glimesh.Socials.Twitter.authorize_url!(conn)

    render(conn, "profile.html", twitter_auth_url: twitter_auth_url)
  end

  def stream(conn, _params) do
    render(conn, "stream.html")
  end

  def preference(conn, _params) do
    render(conn, "preference.html")
  end

  def update_preference(conn, %{"user_preference" => params}) do
    user = conn.assigns.current_user
    current_user_pref = Accounts.get_user_preference!(user)

    case Accounts.update_user_preference(current_user_pref, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Preferences updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :preference))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "preference.html", profile_changeset: changeset)
    end
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

  def create_channel(conn, _params) do
    user = conn.assigns.current_user

    case Streams.create_channel(user) do
      {:ok, _} ->
        conn
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :stream))
        |> redirect(to: "/users/settings/stream")

      {:error, changeset} ->
        render(conn, "stream.html", channel_changeset: changeset)
    end
  end

  def delete_channel(conn, _params) do
    user = conn.assigns.current_user
    channel = Streams.get_channel_for_username!(user.username)

    case Streams.delete_channel(user, channel) do
      {:ok, _} ->
        conn
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :stream))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "stream.html", channel_changeset: changeset)
    end
  end

  def update_channel(conn, %{"channel" => channel_params}) do
    channel = conn.assigns.channel
    user = conn.assigns.current_user

    case Streams.update_channel(user, channel, channel_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Stream settings updated successfully"))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :stream))
        |> UserAuth.log_in_user(conn.assigns.current_user)

      {:error, changeset} ->
        render(conn, "stream.html", channel_changeset: changeset)
    end
  end

  defp assign_profile_changesets(conn, _opts) do
    user = conn.assigns.current_user
    user_preference = Accounts.get_user_preference!(user)

    conn
    |> assign(:user, user)
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
    |> assign(:preference_changeset, Accounts.change_user_preference(user_preference))
  end

  defp assign_channel_changesets(conn, _opts) do
    channel = Streams.get_channel_for_username!(conn.assigns.current_user.username)

    if channel do
      conn
      |> assign(:channel, channel)
      |> assign(:channel_changeset, Streams.change_channel(channel))
      |> assign(:categories, Streams.list_categories_for_select())
    else
      conn |> assign(:channel, channel)
    end
  end
end
