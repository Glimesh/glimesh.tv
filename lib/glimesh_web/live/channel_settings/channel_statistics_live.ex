defmodule GlimeshWeb.ChannelSettings.ChannelStatisticsLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/settings/channel_statistics"}>
      <:title><%= gettext("Statistics") %></:title>

      <div class="p-6">
        <div class="alert alert-info" role="alert">
          <strong><%= gettext("Early Feature Alert!") %></strong>
          Hey there! Channel Statistics are a new feature still under heavy development. We're continually building this new feature, and we'd love your opinion on how we should do it. Thank you!
        </div>

        <table class="table">
          <thead>
            <tr>
              <th><%= gettext("Stream title") %></th>
              <th><%= gettext("Stream started") %></th>
              <th><%= gettext("Stream ended") %></th>
              <th><%= gettext("Category") %></th>
              <th><%= gettext("Peak Viewers") %></th>
              <th><%= gettext("Raids") %></th>
              <th><%= gettext("Raid Viewers") %></th>
            </tr>
          </thead>
          <tbody id="channel-statistics" phx-update="append" data-page={@streams.page_number}>
            <%= for stream <- @streams.entries do %>
              <tr id={"stats-row-#{stream.id}"}>
                <td><%= stream.title %></td>
                <td><%= stream.started_at %></td>
                <td><%= stream.ended_at %></td>
                <td><%= stream.category.name %></td>
                <td><%= stream.peak_viewers %></td>
                <td><%= stream.count_raids %></td>
                <td><%= stream.count_raid_viewers %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <.button phx-click="load_more">Load More</.button>
      </div>
    </Settings.page>
    """
  end

  def mount(_params, _session, socket) do
    results_page = Glimesh.Streams.list_paged_streams(socket.assigns.channel)

    {:ok,
     socket
     |> put_page_title(gettext("Channel Statistics"))
     |> assign(:streams, results_page)}
  end

  def handle_event("load_more", _params, socket) do
    results_page =
      Glimesh.Streams.list_paged_streams(
        socket.assigns.channel,
        socket.assigns.streams.page_number + 1
      )

    {:noreply, socket |> assign(:streams, results_page)}
  end
end
