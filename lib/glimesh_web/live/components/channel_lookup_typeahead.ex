defmodule GlimeshWeb.Components.ChannelLookupTypeahead do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
        <input type="text" name="<%= @field %>" value="<%= @value %>" class="<%= @field %>-input <%= @class %>" phx-debounce="<%= @timeout %>" autocomplete="off" <%= if assigns[:extra_params], do: @extra_params, else: "" %>>
        <%= if @matches != [] do %>
        <div class="channel-typeahead-dropdown list-group">
          <%= for match <- @matches do %>
              <div id="channel-lookup-<%= match.user.id %>" class="list-group-item bg-primary-hover" phx-hook="ChannelLookupTypeahead" data-fieldname="<%= @field %>" data-id="<%= match.user.id %>" data-name="<%= match.user.displayname %>" data-channel-id="<%= match.id %>">
                <img class="img-avatar" src="<%= Glimesh.Avatar.url({match.user.avatar, match.user}, :original) %>" width=50 height=50>&nbsp;<%= match.user.displayname %>
              </div>
          <% end %>
        </div>
        <% end %>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(value: "")}
  end
end
