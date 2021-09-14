defmodule GlimeshWeb.UserSettings.Components.ProfileSettingsLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    pronouns_list = Glimesh.Accounts.Profile.list_pronouns()

    {:ok,
     socket
     |> put_flash(:info, nil)
     |> assign(:profile_changeset, session["profile_changeset"])
     |> assign(:twitter_auth_url, session["twitter_auth_url"])
     |> assign(:user, session["user"])
     |> assign(:route, session["route"])
     |> assign(:pronouns, pronouns_list)}
  end
end
