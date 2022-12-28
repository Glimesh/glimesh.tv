defmodule GlimeshWeb.Channels.Components.ChannelPreview do
  use GlimeshWeb, :component

  alias Glimesh.Streams.Stream
  alias GlimeshWeb.Router.Helpers, as: Routes

  alias GlimeshWeb.Components.UserEffects

  import GlimeshWeb.Gettext

  attr :channel, Glimesh.Streams.Channel, required: true
  attr :class, :string, default: ""

  def thumbnail_and_info(assigns) do
    ~H"""
    <div class={@class}>
      <.link navigate={Routes.user_stream_path(GlimeshWeb.Endpoint, :index, @channel.user.username)}>
        <div class="flex flex-col justify-between bg-gray-800 rounded-md h-full transition duration-150 hover:scale-105">
          <div class="relative">
            <img
              src={
                Glimesh.StreamThumbnail.url({@channel.stream.thumbnail, @channel.stream}, :original)
              }
              alt={@channel.title}
              class="rounded-t-md"
              height="468"
              width="832"
            />

            <div class="absolute inset-0 m-2">
              <div class="absolute top-0 left-0">
                <span class="badge badge-primary text-gray-100"><%= @channel.category.name %></span>
              </div>
              <div class="absolute top-0 right-0">
                <%= if @channel.subcategory do %>
                  <span class="badge badge-info"><%= @channel.subcategory.name %></span>
                <% end %>
              </div>
              <div class="absolute bottom-0 left-0 right-0 max-h-12 overflow-hidden">
                <%= for tag <- @channel.tags do %>
                  <span class="badge badge-info truncate"><%= tag.name %></span>
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex-1 flex flex-col justify-around p-2">
            <h6 class="mb-0 line-clamp-1"><%= @channel.title %></h6>
            <p class="mt-1 mb-0">
              <UserEffects.avatar user={@channel.user} class="h-8 w-8 inline" />
              <UserEffects.displayname user={@channel.user} />
              <%= if language = Glimesh.Streams.get_channel_language(@channel) || "English" do %>
                <span class="badge badge-info">
                  <%= language %>
                </span>
              <% end %>
              <%= if true do %>
                <span class="badge badge-warning ml-1"><%= gettext("Mature") %></span>
              <% end %>
            </p>
          </div>
        </div>
      </.link>
    </div>
    """
  end
end
