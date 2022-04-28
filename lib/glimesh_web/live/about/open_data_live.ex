defmodule GlimeshWeb.About.OpenDataLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mt-4">
      <h2><%= gettext("Open Data") %></h2>
      <p>
        <%= gettext(
          "Glimesh takes transparency to the exteme, as an open company we build in the public light, and we operate in the public light. We've built graphs for a couple common metrics we use, but if you have any questions about how we run, let us know!"
        ) %>
      </p>
      <div class="row mt-4">
        <div class="col-md-4">
          <div class="list-group">
            <%= live_redirect to: Routes.open_data_path(@socket, :index), class: "list-group-item list-group-item-action" do %>
              <div class="d-flex w-100 justify-content-between">
                <h5 class="mb-1"><%= gettext("Platform User Growth") %></h5>
              </div>
              <p class="mb-1">
                <%= gettext("Number of users on the platform over time, and net-new each week.") %>
              </p>
            <% end %>
            <%= live_redirect to: Routes.open_data_path(@socket, :subscriptions), class: "list-group-item list-group-item-action" do %>
              <div class="d-flex w-100 justify-content-between">
                <h5 class="mb-1"><%= gettext("Recurring Subscriptions") %></h5>
              </div>
              <p class="mb-1">
                <%= gettext("Channel subscriptions totals by month.") %>
              </p>
            <% end %>
            <%= live_redirect to: Routes.open_data_path(@socket, :streams), class: "list-group-item list-group-item-action" do %>
              <div class="d-flex w-100 justify-content-between">
                <h5 class="mb-1"><%= gettext("Live Streams") %></h5>
              </div>
              <p class="mb-1">
                <%= gettext("Number of unique streamers and peak viewers by week.") %>
              </p>
            <% end %>
          </div>
        </div>
        <div class="col-md-8">
          <div>
            <div
              id="open-data-line-chart"
              data-chart={@chart_data}
              phx-hook="LineChart"
              data-theme={@chart_theme}
            >
            </div>

            <p class="text-center"><%= gettext("Current week / month data updates daily.") %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:chart_data, Jason.encode!(%{}))
     |> assign(:chart_theme, Map.get(session, "site_theme", "dark"))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _) do
    socket
    |> put_page_title(gettext("Platform User Growth"))
    |> assign(:chart_data, Glimesh.Charts.PlatformUserGrowth.json())
  end

  defp apply_action(socket, :subscriptions, _) do
    socket
    |> put_page_title(gettext("Recurring Subscriptions"))
    |> assign(:chart_data, Glimesh.Charts.RecurringSubscriptions.json())
  end

  defp apply_action(socket, :streams, _) do
    socket
    |> put_page_title(gettext("Live Streams"))
    |> assign(:chart_data, Glimesh.Charts.LiveStreams.json())
  end
end
