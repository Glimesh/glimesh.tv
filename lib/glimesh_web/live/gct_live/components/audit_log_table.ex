defmodule GlimeshWeb.GctLive.Components.AuditLogTable do
  use GlimeshWeb, :live_view

  alias Glimesh.CommunityTeam

  @impl true
  def render(assigns) do
    ~L"""
    <div class="card mt-4">
      <div class="card-header">
          <h5><%= gettext("GCT Audit Log") %></h5>
      </div>
      <div class="card-body">
          <table class="table">
              <thead>
              <tr>
                  <th><%= gettext("User") %></th>
                  <th><%= gettext("Action") %></th>
                  <th><%= gettext("Target") %></th>
                  <th><%= gettext("Timestamp") %></th>
              </tr>
              </thead>
              <tbody>
              <%= for log <- @audit_log do %>
              <tr>
                  <td><%= log.user.displayname %></td>
                  <td><%= log.action %></td>
                  <td><%= log.target %></td>
                  <td><%= log.inserted_at %></td>
              </tr>
              <% end %>
              </tbody>
          </table>
          <button class="btn btn-primary" phx-click="nav" phx-value-page="<%= @page_number - 1%>" <%= if @page_number <= 1, do: "disabled" %>>Previous</button>
          <%= for idx <- Enum.to_list(1..@total_pages) do %>
          <button class="btn btn-primary" phx-click="nav" phx-value-page="<%= idx %>" <%= if @page_number == idx, do: "disabled" %>><%= idx %></button>
          <% end %>
          <button class="btn btn-primary" phx-click="nav" phx-value-page="<%= @page_number + 1%>" <%= if @page_number >= @total_pages, do: "disabled" %>>Next</button>
      </div>
    </div>
    """
  end

  def mount(_params, session, socket) do
    %{entries: entries, page_number: page_number, page_size: page_size, total_entries: total_entries, total_pages: total_pages} =
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
      total_pages: total_pages || 0
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, assign(socket, get_and_assign_page(page))}
  end

  def get_and_assign_page(page_number) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = CommunityTeam.list_all_audit_entries(page: page_number)

    [
      audit_log: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end

end
