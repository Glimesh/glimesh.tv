defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :surface_live_view

  alias Glimesh.Accounts
  alias Glimesh.QueryCache

  alias GlimeshWeb.Channels.Components.ChannelPreview
  alias GlimeshWeb.Channels.Components.VideoPlayer
  alias GlimeshWeb.Events.Components.EventMedia

  alias Surface.Components.LivePatch

  @impl true
  def render(assigns) do
    ~F"""
    <div class="pride_bg">
      <div class="mt-4 text-center" style="font-family: Roboto;">
        <br>
        <br>
        <div class="font-weight-bold pride_font">
          Glimesh Community Pride
        </div>
        <div class="font-weight-bold pride_font_sub">
          Raising funds and awareness for The Trevor Project this June
        </div>
      </div>

      <br>
      <div class="text-center">
        <a
          href="https://donate.tiltify.com/+glimesh/glimpride"
          target="_blank"
          class="btn btn-lg font-weight-bold shadow-lg text-light bg-success"
        >
          Donate Here
        </a>
        <a
          href="https://www.thetrevorproject.org/"
          target="_blank"
          class="btn btn-lg font-weight-bold shadow-lg text-light bg-TrevorProject"
        >
          About the Trevor Project
        </a>
        <a
          href="https://docs.google.com/forms/d/e/1FAIpQLSfCKGswVF8OptjwTz1DR0ithA3wwcARivMH9Dr3UOdfHdM70A/viewform"
          target="_blank"
          class="btn btn-lg font-weight-bold shadow-lg text-light bg-info"
        >
          Host An Event
        </a>
      </div>

      <div class="container my-4" style="max-width: 600px">
        <p class="text-center font-weight-bold pride_font_raised">
          Amount Raised: ${format_price(@total_raised)} of
          {#if @start_goal_amount !== @final_goal_amount}
            <span class="crossthrough">${format_price(@start_goal_amount)}</span> <span style="font-size: 30px;">${format_price(@final_goal_amount)}!</span>
          {#else}
            <span style="font-size: 30px;">${format_price(@final_goal_amount)}!</span>
          {/if}
        </p>
        <div class="progress shadow" style="height: 32px;">
          <div
            class="progress-bar bg-warning lead text-dark progress-bar-striped progress-bar-animated"
            role="progressbar"
            aria-valuenow={@total_raised}
            aria-valuemin="0"
            aria-valuemax={@final_goal_amount}
            style={"width: #{@total_raised / @final_goal_amount * 100}%;"}
          >
            ${format_price(@total_raised)} of ${format_price(@final_goal_amount)}
          </div>
        </div>
      </div>

      {#if @random_channel}
        <div class="container">
          {#if not is_nil(@live_featured_event_channel)}
            <div class="card shadow rounded">
              <div class="row">
                <div class="col-md-7">
                  <VideoPlayer id="homepage-video-player" muted channel={@live_featured_event_channel} />
                </div>
                <div class="col-md-5 py-4 pr-4">
                  <EventMedia event={@live_featured_event} show_img={false} />
                </div>
              </div>
            </div>
          {#else}
            <VideoPlayer id="homepage-video-player" muted channel={@random_channel} />
            <div class="d-flex align-items-start pride_frame">
              <img
                src={Glimesh.Avatar.url({@random_channel.user.avatar, @random_channel.user}, :original)}
                alt={@random_channel.user.displayname}
                width="48"
                height="48"
                class={[
                  "img-avatar mr-2",
                  if(Glimesh.Accounts.can_receive_payments?(@random_channel.user),
                    do: "img-verified-streamer"
                  )
                ]}
              />
              <div class="pl-1 pr-1">
                <h6 class="mb-0 mt-1 text-wrap pride_channel_title">
                  {@random_channel.title}
                </h6>
                <p class="mb-0 card-stream-username">
                  {@random_channel.user.displayname}
                  <span class="badge badge-info">
                    {Glimesh.Streams.get_channel_language(@random_channel)}
                  </span>
                  {#if @random_channel.mature_content}
                    <span class="badge badge-warning ml-1">{gettext("Mature")}</span>
                  {/if}
                </p>
              </div>
              <LivePatch
                to={Routes.user_stream_path(@socket, :index, @random_channel.user.username)}
                class="ml-auto text-md-nowrap mt-1"
              >
                <button type="button" class="btn btn-primary">{gettext("Watch Live")}</button>
              </LivePatch>
            </div>
          {/if}
        </div>
      {#else}
        <!-- <.header_component current_user={@current_user} user_count={@user_count} /> -->
      {/if}

      {#if length(@channels) > 0}
        <div class="container container-stream-list">
          <div class="row">
            {#for channel <- @channels}
              <ChannelPreview channel={channel} class="col-sm-12 col-md-6 col-xl-4 mt-2 mt-md-4" />
            {/for}
          </div>
        </div>
      {/if}
      <!-- <.categories_component /> -->
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    maybe_user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channels = get_cached_channels()

    random_channel = get_random_channel(channels)

    upcoming_event = Glimesh.EventsTeam.get_one_upcoming_event()

    [live_featured_event, live_featured_event_channel] = get_random_event()

    user_count = Glimesh.Accounts.count_users()

    [total_raised, start_goal_amount, final_goal_amount] = get_tiltify_donation_total()

    if connected?(socket) do
      live_channel_id =
        cond do
          not is_nil(live_featured_event_channel) -> live_featured_event_channel.id
          not is_nil(random_channel) -> random_channel.id
          true -> nil
        end

      if live_channel_id do
        VideoPlayer.play("homepage-video-player", Map.get(session, "country"))

        Glimesh.Presence.track_presence(
          self(),
          Glimesh.Streams.get_subscribe_topic(:viewers, live_channel_id),
          session["unique_user"],
          %{}
        )
      end
    end

    {:ok,
     socket
     |> put_page_title()
     |> assign(:upcoming_event, upcoming_event)
     |> assign(:live_featured_event, live_featured_event)
     |> assign(:live_featured_event_channel, live_featured_event_channel)
     |> assign(:channels, channels)
     |> assign(:random_channel, random_channel)
     |> assign(:random_channel_thumbnail, get_stream_thumbnail(random_channel))
     |> assign(:user_count, user_count)
     |> assign(:total_raised, total_raised)
     |> assign(:start_goal_amount, start_goal_amount)
     |> assign(:final_goal_amount, final_goal_amount)
     |> assign(:current_user, maybe_user)}
  end

  def get_random_event do
    QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_random_event()", fn ->
      live_featured_events = Glimesh.EventsTeam.get_potentially_live_featured_events()

      if length(live_featured_events) > 0 do
        random_event = Enum.random(live_featured_events)
        random_channel = Glimesh.ChannelLookups.get_channel_for_username(random_event.channel)

        if Glimesh.Streams.is_live?(random_channel) do
          {:ok, [random_event, random_channel]}
        else
          {:ok, [nil, nil]}
        end
      else
        {:ok, [nil, nil]}
      end
    end)
  end

  def get_tiltify_donation_total do
    access_token = Application.get_env(:glimesh, :tiltify_access_token)

    QueryCache.get_and_store!(
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
             %{
               "data" => %{
                 "totalAmountRaised" => amount_raised,
                 "fundraiserGoalAmount" => final_goal,
                 "originalFundraiserGoal" => original_goal
               }
             } <- response do
          {:ok, [amount_raised * 100, original_goal * 100, final_goal * 100]}
        else
          _ ->
            {:ok, [0, 500, 1000]}
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
    QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_cached_channels()", fn ->
      {:ok, Glimesh.Homepage.get_homepage()}
    end)
  end

  defp get_random_channel(channels) when length(channels) > 0 do
    QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_random_channel()", fn ->
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
end
