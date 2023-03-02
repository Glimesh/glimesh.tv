defmodule GlimeshWeb.UserSettingsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams
  alias GlimeshWeb.ChannelSettingsLive
  alias GlimeshWeb.UserAuth

  alias Phoenix.LiveView.Controller

  plug :put_layout, "user-sidebar.html"

  plug :assign_profile_changesets
  plug :assign_channel_changesets

  def profile(conn, _params) do
    render(conn, "profile.html", page_title: format_page_title(gettext("Your Profile")))
  end

  def stream(conn, _params) do
    launched = Glimesh.has_launched?()

    render(conn, "stream.html",
      page_title: format_page_title(gettext("Channel Settings")),
      launched: launched
    )
  end

  def emotes(conn, _params) do
    conn
    |> Controller.live_render(ChannelSettingsLive.ChannelEmotes)
  end

  def upload_emotes(conn, _params) do
    conn
    |> Controller.live_render(ChannelSettingsLive.UploadEmotes)
  end

  def hosting(conn, _params) do
    conn
    |> Controller.live_render(ChannelSettingsLive.Hosting)
  end

  def raiding(conn, _params) do
    conn
    |> Controller.live_render(ChannelSettingsLive.Raiding)
  end

  def preference(conn, _params) do
    render(conn, "preference.html", page_title: format_page_title(gettext("Preferences")))
  end

  def notifications(conn, _params) do
    render(conn, "notifications.html", page_title: format_page_title(gettext("Notifications")))
  end

  def channel_statistics(conn, _params) do
    conn
    |> Controller.live_render(GlimeshWeb.UserSettings.Components.ChannelStatisticsLive)
  end

  def addons(conn, _params) do
    conn
    |> Controller.live_render(ChannelSettingsLive.Addons)
  end

  def update_preference(conn, %{"user_preference" => params}) do
    user = conn.assigns.current_user
    current_user_pref = Accounts.get_user_preference!(user)

    case Accounts.update_user_preference(current_user_pref, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Preferences updated successfully."))
        |> put_session(:user_return_to, ~p"/users/settings/preference")
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
        |> put_session(:user_return_to, ~p"/users/settings/profile")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "profile.html", profile_changeset: changeset)

      {:upload_exit, _} ->
        conn
        |> put_flash(:error, gettext("Problem uploading avatar, please try again later."))
        |> redirect(to: ~p"/users/settings/profile")
    end
  end

  def create_channel(conn, _params) do
    user = conn.assigns.current_user

    case Streams.create_channel(user) do
      {:ok, _} ->
        conn
        |> put_session(:user_return_to, ~p"/users/settings/stream")
        |> redirect(to: "/users/settings/stream")

      {:error, changeset} ->
        render(conn, "stream.html",
          channel_changeset: changeset,
          launched: Glimesh.has_launched?()
        )
    end
  end

  def delete_channel(conn, _params) do
    user = conn.assigns.current_user
    channel = ChannelLookups.get_channel_for_username(user.username)

    case Streams.delete_channel(user, channel) do
      {:ok, _} ->
        conn
        |> put_session(:user_return_to, ~p"/users/settings/stream")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "stream.html",
          channel_changeset: changeset,
          launched: Glimesh.has_launched?()
        )
    end
  end

  def update_channel(conn, %{"channel" => channel_params}) do
    channel = conn.assigns.channel
    user = conn.assigns.current_user

    launched = Glimesh.has_launched?()

    case Streams.update_channel(user, channel, channel_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Stream settings updated successfully"))
        |> put_session(:user_return_to, ~p"/users/settings/stream")
        |> UserAuth.log_in_user(conn.assigns.current_user)

      {:error, changeset} ->
        render(conn, "stream.html",
          channel_changeset: changeset,
          launched: launched,
          launched: Glimesh.has_launched?()
        )

      {:upload_exit, _} ->
        conn
        |> put_flash(:error, gettext("Problem uploading stream images, please try again later."))
        |> redirect(to: ~p"/users/settings/stream")
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
    channel = ChannelLookups.get_channel_for_username(conn.assigns.current_user.username)

    if channel do
      conn
      |> assign(:channel, channel)
      |> assign(:channel_changeset, Streams.change_channel(channel))
      |> assign(:categories, ChannelCategories.list_categories_for_select())
    else
      conn |> assign(:channel, channel)
    end
  end
end
