defmodule GlimeshWeb.ChannelSettingsLive.ChannelEmotes do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])
    channel = Glimesh.ChannelLookups.get_channel_for_user(user)

    static_emotes = Glimesh.Emotes.list_static_emotes_for_channel(channel)
    animated_emotes = Glimesh.Emotes.list_animated_emotes_for_channel(channel)

    if length(static_emotes ++ animated_emotes) > 0 do
      {:ok,
       socket
       |> put_page_title(gettext("Channel Emotes"))
       |> assign(:user, user)
       |> assign(:channel, channel)
       |> assign(:static_emotes, static_emotes)
       |> assign(:animated_emotes, animated_emotes)}
    else
      {:ok, redirect(socket, to: Routes.user_settings_path(socket, :upload_emotes))}
    end
  end
end
