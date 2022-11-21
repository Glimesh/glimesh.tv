defmodule GlimeshWeb.Events.Components.EventMedia do
  use Surface.Component

  alias Glimesh.EventsTeam.Event
  alias GlimeshWeb.Router.Helpers, as: Routes

  prop event, :struct
  prop show_img, :boolean, default: true
  prop class, :css_class

  slot footer

  def render(%{event: %Event{}} = assigns) do
    ~F"""
    <div class={"media", @class}>
      <img
        :if={@show_img}
        src={Glimesh.EventImage.url({@event.image, @event.image}, :original)}
        style="max-height: 225px"
        alt={@event.label}
      />
      <div class={["media-body", "ml-4": @show_img]}>
        <span class="badge badge-pill text-dark" style={badge_style(@event)}>{@event.type}</span>
        <h5>
          {@event.label}<br>
          <small class="text-muted">
            {Calendar.strftime(
              @event.start_date,
              "%B %d#{Glimesh.EventsTeam.get_day_ordinal(@event.start_date)} %I:%M%p"
            )} Eastern
          </small>
        </h5>
        <p>{@event.description}</p>
        <p>
          {#if Glimesh.EventsTeam.live_now(@event)}
            <span class="badge badge-pill badge-danger">Live now</span>
          {#else}
            Event live <relative-time phx-update="ignore" datetime={Glimesh.EventsTeam.date_to_utc(@event.start_date)} />
          {/if}
          on <a href={event_link(@event)}>glimesh.tv/{@event.channel}</a>
        </p>
        <#slot {@footer}>
          <a class="btn btn-primary" href={event_link(@event)}>Watch Channel</a>
        </#slot>
      </div>
    </div>
    """
  end

  defp badge_style(event) do
    event_color = Glimesh.EventsTeam.get_event_color(event)
    "vertical-align: middle; border-color: #{event_color}; background: #{event_color};"
  end

  defp event_link(%Event{channel: channel}) do
    Routes.user_stream_path(GlimeshWeb.Endpoint, :index, channel)
  end
end
