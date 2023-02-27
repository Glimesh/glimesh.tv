defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :surface_live_view

  alias Glimesh.Accounts
  alias Glimesh.QueryCache

  alias GlimeshWeb.Channels.Components.ChannelPreview
  alias GlimeshWeb.Channels.Components.VideoPlayer
  alias GlimeshWeb.Events.Components.EventMedia

  alias Surface.Components.LiveRedirect

  @impl true
  def render(assigns) do
    ~F"""
    <div class="fancy-bg pt-4">
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
            <div class="row">
              <div class="col-md-7">
                <div class="card shadow rounded">
                  <VideoPlayer id="homepage-video-player" muted channel={@random_channel} />
                  <div class="d-flex align-items-start p-2">
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
                    <LiveRedirect
                      to={~p"/#{@random_channel.user.username}"}
                      class="ml-auto text-md-nowrap mt-1 btn btn-primary"
                    >{gettext("Watch Live")}
                    </LiveRedirect>
                  </div>
                </div>
              </div>
              <div class="col-md-5 py-4 pr-4">
                <div class="d-flex flex-column align-items-center justify-content-center h-100">
                  <h2 class="font-weight-bold">
                    <span class="text-color-alpha">{gettext("Next-Gen")}</span>
                    {gettext("Live Streaming!")}
                  </h2>
                  <p class="lead">
                    {gettext(
                      "The first live streaming platform built around truly real time interactivity. Our streams are warp speed, our chat is blazing, and our community is thriving."
                    )}
                  </p>

                  {#if @current_user}
                    <div class="d-flex flex-row justify-content-around mt-3">
                      {link(gettext("Create Your Channel"),
                        to: ~p"/users/settings/stream",
                        class: "btn btn-info mr-4"
                      )}
                      {link(gettext("Setup Payouts"),
                        to: ~p"/users/settings/profile",
                        class: "btn btn-info"
                      )}
                    </div>
                  {#else}
                    <p class="lead">
                      {gettext("Join %{user_count} others!", user_count: @user_count)}
                    </p>
                    {link(gettext("Register Your Account"),
                      to: ~p"/users/register",
                      class: "btn btn-primary btn-lg"
                    )}
                  {/if}
                </div>
              </div>
            </div>
          {/if}
        </div>
      {#else}
        <div class="container">
          <div class="position-relative overflow-hidden p-3 p-md-5">
            <div class="col-md-12 p-lg-4 mx-auto">
              <h1 class="display-3 font-weight-bold">
                <span class="text-color-alpha">{gettext("Next-Gen")}</span>
                {gettext("Live Streaming!")}
              </h1>
              <p class="lead" style="max-width: 550px;">
                {gettext(
                  "The first live streaming platform built around truly real time interactivity. Our streams are warp speed, our chat is blazing, and our community is thriving."
                )}
              </p>

              {#if @current_user}
                {link(gettext("Customize Your Profile"),
                  to: ~p"/users/settings/profile",
                  class: "btn btn-info mt-3"
                )}
                {link(gettext("Create Your Channel"),
                  to: ~p"/users/settings/stream",
                  class: "btn btn-info mt-3"
                )}
                {link(gettext("Setup Payouts"),
                  to: "/users/settings/profile",
                  class: "btn btn-info mt-3"
                )}
              {#else}
                <p class="lead">
                  {gettext("Join %{user_count} others!", user_count: @user_count)}
                </p>
                {link(gettext("Register Your Account"),
                  to: ~p"/users/register",
                  class: "btn btn-primary btn-lg mt-3"
                )}
              {/if}
            </div>
          </div>
        </div>
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

      <div class="container">
        <div class="mt-4 px-4 px-lg-0">
          <h2>{gettext("Categories Made Simpler")}</h2>
          <p class="lead">{gettext("Explore our categories and find your new home!")}</p>
        </div>
        <div class="row mt-2 mb-4">
          {#for {name, link, icon} <- list_categories()}
            <div class="col">
              <LiveRedirect to={link} class="btn btn-outline-primary btn-lg btn-block py-4">
                <i class={"fas fa-2x fa-fw", icon} />
                <br>
                <small class="text-color-link">{name}</small>
              </LiveRedirect>
            </div>
          {/for}
        </div>
      </div>
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
     |> assign(:current_user, maybe_user)}
  end

  def list_categories do
    [
      {
        gettext("Gaming"),
        ~p"/streams/gaming",
        "fa-gamepad"
      },
      {
        gettext("Art"),
        ~p"/streams/art",
        "fa-palette"
      },
      {
        gettext("Music"),
        ~p"/streams/music",
        "fa-headphones"
      },
      {
        gettext("Tech"),
        ~p"/streams/tech",
        "fa-microchip"
      },
      {
        gettext("IRL"),
        ~p"/streams/irl",
        "fa-camera-retro"
      },
      {
        gettext("Education"),
        ~p"/streams/education",
        "fa-graduation-cap"
      }
    ]
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
end
