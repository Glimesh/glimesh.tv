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
    <div class="pride_bg">
    <div class="container">
    <div class="position-relative overflow-hidden p-3 p-md-5">
      <div class="col-md-12 p-lg-4 mx-auto">
        <h1 class="display-3 font-weight-bold">
        Here lies
          <span class="text-color-alpha">Glimesh.</span>
        </h1>
        <p class="lead" style="max-width: 550px;">
        The streaming site built by the community, for the community. We had a good run, thank you everyone for your love, support, and fellowship.
        </p>
      </div>
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
    [total_raised, start_goal_amount, final_goal_amount] = get_tiltify_donation_total()

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
     |> assign(:total_raised, total_raised)
     |> assign(:start_goal_amount, start_goal_amount)
     |> assign(:final_goal_amount, final_goal_amount)
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
      all_live_channels = Glimesh.ChannelLookups.search_live_channels(%{})
      {:ok, all_live_channels}
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

  def get_tiltify_donation_total do
    access_token = Application.get_env(:glimesh, :tiltify_access_token)

    QueryCache.get_and_store!(
      "GlimeshWeb.HomepageLive.get_tiltify_donation_total()",
      fn ->
        with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
               HTTPoison.get(
                 "https://tiltify.com/api/v3/campaigns/497112",
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
end
