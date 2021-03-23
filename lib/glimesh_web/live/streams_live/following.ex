defmodule GlimeshWeb.StreamsLive.Following do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @impl true
  def render(assigns) do
    ~L"""
    <div class="container container-stream-list">
      <div class="position-relative overflow-hidden p-3 p-md-5 m-md-3 text-center">
          <div class="col-md-12 mx-auto ">
              <h1 class="display-4 font-weight-normal">
                  <%= gettext("Followed Streams") %>
              </h1>
              <%= if length(@channels) == 0 do %>
              <p><%= gettext("None of the streams you follow are live.") %></p>
              <% end %>
          </div>
      </div>
      <div class="row">
        <%= for channel <- @channels do %>
          <div class="col-sm-12 col-md-6 col-xl-4 mt-4">
              <%= link to: Routes.user_stream_path(@socket, :index, channel.user.username), class: "text-color-link" do %>
              <div class="card card-stream">
                  <img src="<%= Glimesh.StreamThumbnail.url({channel.stream.thumbnail, channel.stream}, :original) %>" alt="<%= channel.title %>" class="card-img" height="468" width="832">
                  <div class="card-img-overlay h-100 d-flex flex-column justify-content-between">

                      <div class="card-stream-tags">

                          <%= if channel.subcategory do %>
                          <span class="badge badge-info"><%= channel.subcategory.name %></span>
                          <% end %>
                          <%= for tag <- channel.tags do %>
                          <span class="badge badge-primary"><%= tag.name %></span>
                          <% end %>
                      </div>

                      <div class="media card-stream-streamer">
                          <img src="<%= Glimesh.Avatar.url({channel.user.avatar, channel.user}, :original) %>" alt="<%= channel.user.displayname%>" width="48" height="48" class="img-avatar mr-2 <%= if Glimesh.Accounts.can_receive_payments?(channel.user), do: "img-verified-streamer", else: "" %>">
                          <div class="media-body">
                              <h6 class="mb-0 mt-1 card-stream-title"><%= channel.title %></h6>
                              <p class="mb-0 card-stream-username"><%= channel.user.displayname %> <span class="badge badge-info"><%= Glimesh.Streams.get_channel_language(channel) %></span></p>
                          </div>
                      </div>
                  </div>
              </div>
              <% end %>
          </div>
          <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    case Accounts.get_user_by_session_token(session["user_token"]) do
      %Glimesh.Accounts.User{} = user ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        live_streams = Glimesh.ChannelLookups.list_live_followed_channels(user)

        {:ok,
         socket
         |> put_page_title(gettext("Followed Streams"))
         |> assign(:current_user, user)
         |> assign(:channels, live_streams)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
