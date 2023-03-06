defmodule GlimeshWeb.Channel.Components.ChannelTitle do
  use GlimeshWeb, :component

  attr :channel, Glimesh.Streams.Channel, required: true

  def uneditable_title(assigns) do
    ~H"""
    <div>
      <h1 class="text-xl line-clamp-1"><%= @channel.title %></h1>
      <div class="space-x-1">
        <.link navigate={~p"/streams/#{@channel.category.slug}"} class="badge badge-primary">
          <%= @channel.category.name %>
        </.link>
        <%= if @channel.subcategory do %>
          <.link
            navigate={
              ~p"/streams/#{@channel.category.slug}?subcategory[]=#{@channel.subcategory.slug}"
            }
            class="badge badge-pill badge-info"
          >
            <%= @channel.subcategory.name %>
          </.link>
        <% end %>
        <%= for tag <- @channel.tags do %>
          <.link
            navigate={~p"/streams/#{@channel.category.slug}?tags[]=#{tag.slug}"}
            class="badge badge-pill"
          >
            <%= tag.name %>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
