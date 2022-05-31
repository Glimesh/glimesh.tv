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
     |> assign(:total_raised, get_tiltify_donation_total())
     |> assign(:current_user, maybe_user)}
  end

  def get_tiltify_donation_total() do
    access_token = Application.get_env(:glimesh, :tiltify_access_token)

    Glimesh.QueryCache.get_and_store!(
      "GlimeshWeb.HomepageLive.get_tiltify_donation_total()",
      fn ->
        with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
               HTTPoison.get(
                 "https://tiltify.com/api/v3/campaigns/171961",
                 [
                   {"Authorization", "Bearer #{access_token}"},
                   {"Content-Type", "application/json"}
                 ]
               ),
             {:ok, response} <- Jason.decode(body),
             %{"data" => %{"totalAmountRaised" => amount_raised}} <- response do
          {:ok, amount_raised}
        else
          _ ->
            {:ok, 0}
        end
      end
    )
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
                      <span class="badge badge-info"><%= channel.subcategory.name %></span>
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

  def header_component(assigns) do
    ~H"""
    <div class="fancy-bg">
      <div class="container">
        <div class="position-relative overflow-hidden p-3 p-md-5">
          <div class="col-md-12 p-lg-4 mx-auto">
            <h1 class="display-3 font-weight-bold">
              <span class="text-color-alpha"><%= gettext("Next-Gen") %></span>
              <%= gettext("Live Streaming!") %>
            </h1>
            <p class="lead" style="max-width: 500px;">
              <%= gettext(
                "The first live streaming platform built around truly real time interactivity. Our streams are warp speed, our chat is blazing, and our community is thriving."
              ) %>
            </p>
            <%= if @current_user do %>
              <%= link(gettext("Customize Your Profile"),
                to: Routes.user_settings_path(GlimeshWeb.Endpoint, :profile),
                class: "btn btn-info mt-3"
              ) %>
              <%= link(gettext("Create Your Channel"),
                to: Routes.user_settings_path(GlimeshWeb.Endpoint, :stream),
                class: "btn btn-info mt-3"
              ) %>
              <%= link(gettext("Setup Payouts"),
                to: "/users/settings/profile",
                class: "btn btn-info mt-3"
              ) %>
            <% else %>
              <p class="lead">
                <%= gettext("Join %{user_count} others!", user_count: @user_count) %>
              </p>
              <%= link(gettext("Register Your Account"),
                to: Routes.user_registration_path(GlimeshWeb.Endpoint, :new),
                class: "btn btn-primary btn-lg mt-3"
              ) %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def categories_component(assigns) do
    ~H"""
    <div class="container">
      <div class="mt-4 px-4 px-lg-0">
        <h2><%= gettext("Categories Made Simpler") %></h2>
        <p class="lead"><%= gettext("Explore our categories and find your new home!") %></p>
      </div>
      <div class="row mt-2 mb-4">
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "gaming") do %>
            <i class="fas fa-gamepad fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("Gaming") %></small>
          <% end %>
        </div>
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "art") do %>
            <i class="fas fa-palette fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("Art") %></small>
          <% end %>
        </div>
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "music") do %>
            <i class="fas fa-headphones fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("Music") %></small>
          <% end %>
        </div>
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "tech") do %>
            <i class="fas fa-microchip fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("Tech") %></small>
          <% end %>
        </div>
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "irl") do %>
            <i class="fas fa-camera-retro fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("IRL") %></small>
          <% end %>
        </div>
        <div class="col">
          <%= live_redirect class: "btn btn-outline-primary btn-lg btn-block py-4", to: Routes.streams_list_path(GlimeshWeb.Endpoint, :index, "education") do %>
            <i class="fas fa-graduation-cap fa-2x fa-fw"></i>
            <br />
            <small class="text-color-link"><%= gettext("Education") %></small>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
