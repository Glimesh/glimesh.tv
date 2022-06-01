defmodule GlimeshWeb.EventsLive do
  use GlimeshWeb, :surface_live_view

  alias GlimeshWeb.Events.Components.Calendar
  alias GlimeshWeb.Events.Components.SmallEvent

  @impl true
  def render(assigns) do
    ~F"""
    <div class="container mt-4">
      <div class="row">
        <div class="col-md-5">
          <h3 class="text-center">{gettext("Event Calendar")}</h3>

          <Calendar id="events-calendar" />

          <div class="text-center my-4">
            <h3>{gettext("Having an event?")}</h3>
            <p>Want your event featured on Glimesh? Tell us about it, and we might help advertise it!</p>
            <a href="https://forms.gle/6VpqMzc6i1XomaP86/" target="_blank" class="btn btn-info">Submit Event</a>
          </div>
        </div>

        <div class="col-md-7">
          <div class="card">
            <div class="card-body">
              <h3 class="text-center m-0">{gettext("Featured Events")}</h3>
            </div>
          </div>

          {#for event <- @events}
            <SmallEvent event={event} />
          {/for}
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    events = Glimesh.EventsTeam.list_featured_events()

    {:ok,
     socket
     |> put_page_title(gettext("Events"))
     |> assign(events: events)}
  end
end
