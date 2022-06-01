defmodule GlimeshWeb.Events.Components.EventCard do
  use Surface.Component

  alias Glimesh.EventsTeam.Event
  alias GlimeshWeb.Router.Helpers, as: Routes

  prop event, :struct

  prop class, :css_class

  slot footer

  def render(%{event: %Event{}} = assigns) do
    ~F"""
    <div class={"card h-100", @class}>
      <img
        src={Glimesh.EventImage.url({@event.image, @event.image}, :original)}
        class="card-img-top"
        alt={@event.label}
      />
      <div class="card-body">
        <h5>{@event.label}</h5>
        <p class="card-text">{@event.description}</p>
        {#if Glimesh.EventsTeam.live_now(@event)}
          <span class="badge badge-pill badge-danger">Live now</span>
          {live_patch("Watch Event",
            to: Routes.user_stream_path(GlimeshWeb.Endpoint, :index, @event.channel)
          )}
        {#else}
          <p class="text-center">
            Live
            <relative-time
              id="event-relative-time"
              phx-update="ignore"
              datetime={Glimesh.EventsTeam.date_to_utc(@event.start_date)}
            >
              {@event.start_date}
            </relative-time>
            on
            <br>

            {live_patch("glimesh.tv/#{@event.channel}",
              to: Routes.user_stream_path(GlimeshWeb.Endpoint, :index, @event.channel)
            )}
          </p>
        {/if}
      </div>
      <div class="card-footer text-center">
        {Calendar.strftime(
          @event.start_date,
          "%B %d#{Glimesh.EventsTeam.get_day_ordinal(@event.start_date)} %I:%M%p"
        )} Eastern US
      </div>
    </div>
    """
  end
end
