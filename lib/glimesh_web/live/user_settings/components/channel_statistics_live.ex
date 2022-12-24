defmodule GlimeshWeb.UserSettings.Components.ChannelStatisticsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups

  def mount(_params, session, socket) do
    streamer = Accounts.get_user_by_session_token(session["user_token"])

    case ChannelLookups.get_channel_for_user(streamer) do
      %Glimesh.Streams.Channel{} = channel ->
        results_page = Glimesh.Streams.list_paged_streams(channel)

        {:ok,
         socket
         |> put_page_title(gettext("Channel Statistics"))
         |> assign(:streams, results_page)
         |> assign(:channel, channel)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("load-more", _params, socket) do
    streams = socket.assigns.streams
    channel = socket.assigns.channel
    results_page = Glimesh.Streams.list_paged_streams(channel, streams.page_number + 1)

    {:noreply, socket |> assign(:streams, results_page)}
  end
end
