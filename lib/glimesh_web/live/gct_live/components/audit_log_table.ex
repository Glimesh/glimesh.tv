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
      </div>
    </div>
    """
  end

  def mount(_params, _conn, socket) do
    audit_entries = if connected?(socket), do: CommunityTeam.list_all_audit_entries(), else: []

    {:ok,
    socket
    |> assign(:audit_log, audit_entries)}
  end

end
