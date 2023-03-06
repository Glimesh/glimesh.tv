defmodule GlimeshWeb.ChannelSettings.ChannelStatisticsLive do
  use GlimeshWeb, :settings_live_view

  def mount(_params, _session, socket) do
    results_page = Glimesh.Streams.list_paged_streams(socket.assigns.channel)

    {:ok,
     socket
     |> put_page_title(gettext("Channel Statistics"))
     |> assign(:streams, results_page)}
  end

  def handle_event("load-more", _params, socket) do
    results_page =
      Glimesh.Streams.list_paged_streams(
        socket.assigns.channel,
        socket.assigns.streams.page_number + 1
      )

    {:noreply, socket |> assign(:streams, results_page)}
  end
end
