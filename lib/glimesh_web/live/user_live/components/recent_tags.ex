defmodule GlimeshWeb.UserLive.Components.RecentTags do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <%= if length(@recent_tags) > 0 do %>
      <div class="row pb-2">
        <div class="col-2 text-right pr-0 mt-1">
          <p class="text-muted"><%= gettext("Recent:") %></p>
        </div>
        <div class="col-10 pl-1 pt-0">
          <div class="d-flex flex-wrap">
            <%= for recent <- @recent_tags do %>
              <div
                id={"recent-tag-#{@fieldid}-#{recent.id}"}
                class="badge badge-primary recent-tag"
                title={
                  if Map.has_key?(recent, :count_usage),
                    do: gettext("(%{num} Uses)", num: recent.count_usage)
                }
                phx-hook="RecentTags"
                data-operation={@operation}
                data-fieldid={@fieldid}
                data-tagid={recent.id}
                data-tagname={recent.name}
                data-tagslug={recent.slug}
                data-categoryid={recent.category_id}
              >
                <%= recent.name %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
