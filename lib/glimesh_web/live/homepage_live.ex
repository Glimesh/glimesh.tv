defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    maybe_user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channels = get_cached_channels()

    random_channel = get_random_channel(channels)

    featured_event = Glimesh.EventsTeam.get_one_upcoming_event()

    user_count = Glimesh.Accounts.count_users()

    {:ok,
     socket
     |> put_page_title()
     |> assign(:featured_event, featured_event)
     |> assign(:channels, channels)
     |> assign(:random_channel, random_channel)
     |> assign(:random_channel_thumbnail, get_stream_thumbnail(random_channel))
     |> assign(:user_count, user_count)
     |> assign(:current_user, maybe_user)}
  end

  defp get_stream_thumbnail(%Glimesh.Streams.Channel{} = channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
  end

  defp get_stream_thumbnail(nil), do: nil

  defp get_cached_channels do
    Glimesh.QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_cached_channels()", fn ->
      {:ok, Glimesh.Homepage.get_homepage()}
    end)
  end

  defp get_random_channel(channels) when length(channels) > 0 do
    Glimesh.QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_random_channel()", fn ->
      {:ok, Enum.random(channels)}
    end)
  end

  defp get_random_channel(_), do: nil

  @impl Phoenix.LiveView
  def handle_info({:debug, _, _}, socket) do
    # Ignore any debug messages from the video player
    {:noreply, socket}
  end

  def featured_events_component(assigns) do
    ~H"""
    <div class="card h-100">
      <img
        src={Glimesh.EventImage.url({@event.image, @event.image}, :original)}
        class="card-img-top"
        alt={@event.label}
      />
      <div class="card-body">
        <h5><%= @event.label %></h5>
        <p class="card-text"><%= @event.description %></p>
        <%= if Glimesh.EventsTeam.live_now(@event) do %>
          <span class="badge badge-pill badge-danger">Live now</span>
          <%= live_patch("Watch Event",
            to: Routes.user_stream_path(GlimeshWeb.Endpoint, :index, @event.channel)
          ) %>
        <% else %>
          <p class="text-center">
            Live
            <relative-time
              id="event-relative-time"
              phx-update="ignore"
              datetime={Glimesh.EventsTeam.date_to_utc(@event.start_date)}
            >
              <%= @event.start_date %>
            </relative-time>
            on
            <br />

            <%= live_patch("glimesh.tv/#{@event.channel}",
              to: Routes.user_stream_path(GlimeshWeb.Endpoint, :index, @event.channel)
            ) %>
          </p>
        <% end %>
      </div>
      <div class="card-footer text-center">
        <%= Calendar.strftime(
          @event.start_date,
          "%B %d#{Glimesh.EventsTeam.get_day_ordinal(@event.start_date)} %I:%M%p"
        ) %> Eastern US
      </div>
    </div>
    """
  end

  def live_channels_component(assigns) do
    ~H"""
    <div class="row">
      <%= for channel <- @channels do %>
        <div class="col-sm-12 col-md-6 col-xl-4 mt-2 mt-md-4">
          <%= link to: Routes.user_stream_path(GlimeshWeb.Endpoint, :index, channel.user.username), class: "text-color-link" do %>
            <div class="card card-stream">
              <img
                src={
                  Glimesh.StreamThumbnail.url({channel.stream.thumbnail, channel.stream}, :original)
                }
                alt={channel.title}
                class="card-img"
                height="468"
                width="832"
              />
              <div class="card-img-overlay h-100 d-flex flex-column justify-content-between">
                <div>
                  <div class="card-stream-category">
                    <span class="badge badge-primary"><%= channel.category.name %></span>
                  </div>

                  <div class="card-stream-tags">
                    <%= if channel.subcategory do %>
                      <span class="badge "><%= channel.subcategory.name %></span>
                    <% end %>
                  </div>
                </div>

                <div class="media card-stream-streamer">
                  <img
                    src={Glimesh.Avatar.url({channel.user.avatar, channel.user}, :original)}
                    alt={channel.user.displayname}
                    width="48"
                    height="48"
                    class={
                      [
                        "img-avatar mr-2",
                        if(Glimesh.Accounts.can_receive_payments?(channel.user),
                          do: "img-verified-streamer"
                        )
                      ]
                    }
                  />
                  <div class="media-body">
                    <h6 class="mb-0 mt-1 card-stream-title"><%= channel.title %></h6>
                    <p class="mb-0 card-stream-username">
                      <%= channel.user.displayname %>
                      <span class="badge badge-info">
                        <%= Glimesh.Streams.get_channel_language(channel) %>
                      </span>
                      <%= if channel.mature_content do %>
                        <span class="badge badge-warning ml-1"><%= gettext("Mature") %></span>
                      <% end %>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
