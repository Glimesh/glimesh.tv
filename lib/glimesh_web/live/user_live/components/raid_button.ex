defmodule GlimeshWeb.UserLive.Components.RaidButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups
  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="raid-button-hidden-div"
        class="d-none"
        phx-hook="RaidTimer"
        data-raid-counter-id="cancel-raid-timer"
      >
      </div>
      <%= if not @raid_started do %>
        <button
          class="btn btn-primary raid-button btn-responsive"
          phx-click="start_raid"
          phx-throttle="5000"
          data-confirm={gettext("Raiding a streamer will end your stream, are you sure?")}
        >
          <span class="d-none d-lg-block"><%= gettext("Raid") %></span>
          <span class="d-lg-none"><i class="fas fa-bullhorn fa-fw"></i></span>
        </button>
      <% else %>
        <button class="btn btn-primary cancel-raid-button btn-responsive" phx-click="cancel_raid">
          <span class="d-none d-lg-block">
            <%= gettext("Cancel Raid") %>&nbsp;<span id="cancel-raid-timer"></span>
          </span>
          <span class="d-lg-none"><i class="fas fa-bullhorn fa-fw"></i></span>
        </button>
      <% end %>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil, "channel" => channel}, socket) do
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:user, nil)
     |> assign(:show, false)
     |> assign(:raid_started, false)
     |> assign(:raid_payload, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user, "channel" => channel}, socket) do
    Gettext.put_locale(Accounts.get_user_locale(user))

    show_button = streamer.id != user.id

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:user, user)
     |> assign(:show, show_button)
     |> assign(:raid_started, false)
     |> assign(:raid_payload, nil)}
  end

  @impl true
  def handle_event("start_raid", _value, socket) do
    user_channel = ChannelLookups.get_channel_for_user(socket.assigns.user)

    {:ok, topic} = Streams.subscribe_to(:raid, user_channel.id)
    users_present = Presence.list_presences(topic)

    raid_payload =
      Streams.start_raid_channel(
        user_channel.user,
        user_channel,
        socket.assigns.channel,
        users_present
      )

    seconds_till_raid =
      abs(NaiveDateTime.diff(raid_payload[:time], NaiveDateTime.utc_now(), :second))

    {:noreply,
     socket
     |> assign(:raid_started, true)
     |> assign(:raid_payload, raid_payload)
     |> push_event("start_raid_timer", %{time: seconds_till_raid})}
  end

  def handle_event("cancel_raid", _params, socket) do
    user_channel = ChannelLookups.get_channel_for_user(socket.assigns.user)
    raid_payload = socket.assigns.raid_payload
    Streams.cancel_raid_channel(socket.assigns.user, user_channel, raid_payload[:group_id])

    {:noreply,
     socket
     |> assign(:raid_started, false)
     |> assign(:raid_payload, raid_payload)}
  end
end
