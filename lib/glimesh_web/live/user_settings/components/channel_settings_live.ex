defmodule GlimeshWeb.UserSettings.Components.ChannelSettingsLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
    socket
    |> put_flash(:info, nil)
    |> assign(:channel_changeset, session["channel_changeset"])
    |> assign(:categories, session["categories"])
    |> assign(:channel, session["channel"])
    |> assign(:route, session["route"])
    |> assign(:user, session["user"])
    |> assign(:delete_route, session["delete_route"])}
  end

end
