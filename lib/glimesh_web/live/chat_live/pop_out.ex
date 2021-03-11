defmodule GlimeshWeb.ChatLive.PopOut do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups

  def mount(%{"username" => streamer_username}, session, socket) do
    case ChannelLookups.get_channel_for_username(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        # Keep track of viewers using their socket ID, but later we'll keep track of chatters by their user

        maybe_user = Accounts.get_user_by_session_token(session["user_token"])
        # If the viewer is logged in set their locale, otherwise it defaults to English
        if session["locale"], do: Gettext.put_locale(session["locale"])

        {:ok,
         socket
         |> assign(:render_nav, false)
         |> assign(:render_footer, false)
         |> assign(:channel_id, channel.id)
         |> assign(:user, maybe_user)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end
end
