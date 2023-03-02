defmodule GlimeshWeb.Channels.Components.ChannelPreview do
  use Surface.Component

  use GlimeshWeb, :verified_routes

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.Stream

  alias Surface.Components.LivePatch

  import GlimeshWeb.Gettext

  prop channel, :struct

  prop class, :css_class

  def render(%{channel: %Channel{user: %User{}, stream: %Stream{}}} = assigns) do
    ~F"""
    <div class={@class}>
      <LivePatch to={~p"/#{@channel.user.username}"} class="text-color-link">
        <div class="card card-stream">
          <img
            src={Glimesh.StreamThumbnail.url({@channel.stream.thumbnail, @channel.stream}, :original)}
            alt={@channel.title}
            class="card-img"
            height="468"
            width="832"
          />
          <div class="card-img-overlay h-100 d-flex flex-column justify-content-between">
            <div>
              <div class="card-stream-category">
                <span class="badge badge-primary">{@channel.category.name}</span>
              </div>

              <div class="card-stream-tags">
                {#if @channel.subcategory}
                  <span class="badge badge-info">{@channel.subcategory.name}</span>
                {/if}
              </div>
            </div>

            <div class="media card-stream-streamer">
              <img
                src={Glimesh.Avatar.url({@channel.user.avatar, @channel.user}, :original)}
                alt={@channel.user.displayname}
                width="48"
                height="48"
                class={[
                  "img-avatar mr-2",
                  if(Glimesh.Accounts.can_receive_payments?(@channel.user),
                    do: "img-verified-streamer"
                  )
                ]}
              />
              <div class="media-body">
                <h6 class="mb-0 mt-1 card-stream-title">{@channel.title}</h6>
                <p class="mb-0 card-stream-username">
                  {@channel.user.displayname}
                  <span class="badge badge-info">
                    {Glimesh.Streams.get_channel_language(@channel)}
                  </span>
                  {#if @channel.mature_content}
                    <span class="badge badge-warning ml-1">{gettext("Mature")}</span>
                  {/if}
                </p>
              </div>
            </div>
          </div>
        </div>
      </LivePatch>
    </div>
    """
  end
end
