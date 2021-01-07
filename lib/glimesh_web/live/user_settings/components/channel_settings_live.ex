defmodule GlimeshWeb.UserSettings.Components.ChannelSettingsLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
    socket
    |> put_flash(:info, nil)
    |> put_flash(:error, nil)
    |> assign(:channel_changeset, session["channel_changeset"])
    |> assign(:categories, session["categories"])
    |> assign(:channel, session["channel"])
    |> assign(:route, session["route"])
    |> assign(:user, session["user"])
    |> assign(:delete_route, session["delete_route"])
    |> assign(:channel_delete_disabled, session["channel_delete_disabled"])}
  end

end
