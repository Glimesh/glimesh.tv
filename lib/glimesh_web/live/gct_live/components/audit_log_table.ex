defmodule GlimeshWeb.GctLive.Components.AuditLogTable do
  use GlimeshWeb, :live_view

  alias Glimesh.CommunityTeam

  @impl true
  def render(assigns) do
    ~L"""
    <div class="card mt-4">
      <div class="card-header">
      <!--
            <%= form_for :user, "#", [phx_submit: :search] %>
            <div class="input-group">
              <input type="text" class="form-control col-sm-6" name="search_param" id="searchParam"></input>
              <button class="btn btn-primary">Search</button>
            </div> -->
      </div>
      <div class="card-body">
          <table class="table">
              <thead>
              <tr>
                  <th><%= gettext("ID") %></th>
                  <th><%= gettext("User") %></th>
                  <th><%= gettext("Action") %></th>
                  <th><%= gettext("Target") %></th>
                  <th><%= gettext("Timestamp") %></th>
                  <th><%= gettext("Options") %></th>
              </tr>
              </thead>
              <tbody>
              <%= for log <- @audit_log do %>
              <tr>
                  <td><%= log.id %></td>
                  <td><%= log.user.displayname %></td>
                  <td><%= log.action %></td>
                  <td><%= link log.target, to: Routes.gct_path(@conn, :username_lookup, query: log.target) %></td>
                  <td><%= log.inserted_at %> UTC</td>
                  <td>
                    <button class="btn btn-primary btn-sm" phx-click="show-details" phx-value-log-id=<%= log.id%>>Details</button>
                  </td>
              </tr>
              <% end %>
              </tbody>
          </table>
          <button class="btn btn-primary btn-sm" phx-click="nav" phx-value-page="<%= @page_number - 1%>" <%= if @page_number <= 1, do: "disabled" %>><</button>
          <%= for idx <- Enum.to_list(1..@total_pages) do %>
            <%= unless idx > @page_number + 2 || idx < @page_number - 2 do %>
              <button class="btn btn-primary btn-sm" phx-click="nav" phx-value-page="<%= idx %>" <%= if @page_number == idx, do: "disabled" %>><%= idx %></button>
            <% end %>
          <% end %>
          <button class="btn btn-primary btn-sm" phx-click="nav" phx-value-page="<%= @page_number + 1%>" <%= if @page_number >= @total_pages, do: "disabled" %>>></button>
          <%= unless @verbose do %>
            <button class="btn btn-primary float-right" phx-click="show-verbose">Show Verbose Entries</button>
          <% else %>
            <button class="btn btn-primary float-right" phx-click="hide-verbose">Hide Verbose Entries</button>
          <% end %>
      </div>
    </div>
    <%= if @show_details do %>
      <div id="details-modal" class="live-modal"
        phx-capture-click="hide_details_modal"
        phx-window-keydown="hide_details_modal"
        phx-key="escape"
        phx-target="#paymentModal2"
        phx-page-loading>
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title"><%= gettext("Details for Audit Log #%{log_number}", log_number: @detailed_log.id) %></h5>
              <button type="button" class="close" phx-click="hide_details_modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>

            <div class="modal-body">
              <div class="form-group">
                <label for="gctMember"><%= gettext("GCT Member") %></label>
                <input type="text" class="form-control" disabled value="<%= @detailed_log.user.username%>"></input>

                <label for="action" class="mt-1"><%= gettext("Action") %></label>
                <input type="text" class="form-control" disabled value="<%= @detailed_log.action%>"></input>

                <label for="target" class="mt-1"><%= gettext("Target") %></label>
                <input type="text" class="form-control" disabled value="<%= @detailed_log.target%>"></input>

                <label for="changes" class="mt-1"><%= gettext("More Details") %></label>
                <textarea rows="15" class="form-control" disabled><%= @detailed_log.more_details%></textarea>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      if connected?(socket) do
        CommunityTeam.list_all_audit_entries()
      else
        %Scrivener.Page{}
      end

    assigns = [
      conn: socket,
      audit_log: entries,
      page_number: page_number || 0,
      page_size: page_size || 0,
      total_entries: total_entries || 0,
      total_pages: total_pages || 0,
      verbose: false,
      show_details: false,
      detailed_log: %{id: 0, action: "None", target: "None", more_details: "None"}
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, assign(socket, get_and_assign_page(page, socket.assigns.verbose))}
  end

  @impl true
  def handle_event("show-verbose", _params, socket) do
    {:noreply, socket |> assign(get_and_assign_page(1, true)) |> assign(:verbose, true)}
  end

  @impl true
  def handle_event("hide-verbose", _params, socket) do
    {:noreply, socket |> assign(get_and_assign_page(1, false)) |> assign(:verbose, false)}
  end

  @impl true
  def handle_event("show-details", %{"log-id" => log_id}, socket) do
    {:noreply, socket |> assign(:show_details, true) |> assign(:detailed_log, CommunityTeam.get_audit_log_entry_from_id!(log_id))}
  end

  @impl true
  def handle_event("hide_details_modal", _params, socket) do
    {:noreply, socket |> assign(:show_details, false)}
  end

  def get_and_assign_page(page_number, verbose \\ false) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = CommunityTeam.list_all_audit_entries(verbose, page: page_number)

    [
      audit_log: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end
end
