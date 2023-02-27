defmodule GlimeshWeb.Events.EventsAdminLive do
  use GlimeshWeb, :surface_live_view

  alias Glimesh.EventsTeam
  alias Glimesh.EventsTeam.Event
  alias GlimeshWeb.Events.Components.EventMedia

  data changeset, :struct
  data event, :struct

  @impl true
  def render(assigns) do
    ~F"""
    <div class="text-center mt-4 mb-4">
      <h2>{gettext("Events Team Dashboard")}</h2>
    </div>

    <div class="row" style="padding:15px">
      <div class="col-md-5">
        <div class="card">
          <div class="card-body">
            <h4 class="text-center mt-2 mb-4">{gettext("All Events")}</h4>
          </div>

          {#for event <- @all_events}
            <EventMedia event={event} class="p-2">
              <:footer>
                <button
                  class="btn btn-primary"
                  :on-click="select-event"
                  phx-value-eventid={event.id}
                  type="button"
                >
                  Edit
                </button>
                <button
                  class="btn btn-danger"
                  :on-click="delete-event"
                  data-confirm="Are you sure you want to delete this event?"
                  phx-value-eventid={event.id}
                  type="button"
                >
                  Delete
                </button>
              </:footer>
            </EventMedia>
          {/for}
        </div>
      </div>

      <div class="col-7">
        <div class="card">
          <div class="card-body">
            <h4 class="text-center">Event Upload Form</h4>
          </div>
        </div>

        <div class="col-md-20">
          <div class="card mt-2">
            <div class="card-body">
              <.form
                :let={f}
                for={@changeset}
                id="event_image_upload"
                phx-submit="save"
                phx-change="validate"
                multipart
              >
                {hidden_input(f, :id)}
                <div class="row">
                  <div class="col-3">Name of Event</div>

                  <div class="col-9">
                    {text_input(f, :label, class: "form-control")}
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">Description</div>

                  <div class="col-9">
                    {textarea(f, :description, class: "form-control", rows: 5)}
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">Event Image</div>

                  <div class="col-9">
                    <div class="custom-file">
                      {live_file_input(@uploads.image)}
                    </div>

                    {#if @changeset.errors[:image]}
                      <div>
                        <span class="text-danger">
                          {gettext("invalid image. Must be either a PNG or JPG.")}
                        </span>
                      </div>
                    {/if}
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">Channel Name</div>

                  <div class="col-9">
                    {text_input(f, :channel, class: "form-control")}
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">Start Date and Time</div>

                  <div class="col-9">
                    {datetime_select(f, :start_date)}
                  </div>
                </div>
                *Times are Glimtime (Eastern)
                <br>

                <br>

                <div class="row">
                  <div class="col-3">End Date and Time</div>

                  <div class="col-9">{datetime_select(f, :end_date)}</div>
                </div>
                *Times are Glimtime (Eastern)
                <br>
                <br>

                <div class="row">
                  <div class="col-3">Featured Event?</div>

                  <div class="col-9">
                    <div class="custom-control customer-checkbox">
                      {checkbox(f, :featured, class: "custom-control-input")}
                      {label(f, :featured, "Tick here if yes", class: "custom-control-label")}
                    </div>
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">Event Type</div>

                  <div class="col-9">
                    {select(f, :type, @types, class: "form-control")}
                    {error_tag(f, :type)}
                  </div>
                </div>
                <br>

                <div class="row">
                  <div class="col-3">
                    {submit(gettext("Save"), class: "btn btn-primary")}
                  </div>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    all_events = EventsTeam.list_events()

    changeset = EventsTeam.empty_event()

    event_types = EventsTeam.list_types()

    {:ok,
     socket
     |> put_page_title("Events Team")
     |> assign(:all_events, all_events)
     |> assign(:changeset, changeset)
     |> assign(:types, event_types)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.png .jpg .jpeg), max_entries: 1)}
  end

  @impl true
  def handle_event("select-event", %{"eventid" => eventid}, socket) do
    changeset = EventsTeam.get_event(eventid)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("delete-event", %{"eventid" => eventid}, socket) do
    EventsTeam.delete_event(eventid)

    {:noreply,
     socket
     |> redirect(to: ~p"/events/admin")}
  end

  @impl true
  def handle_event("validate", %{"event" => event}, socket) do
    changeset =
      %Event{}
      |> Event.changeset(event)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"event" => event}, socket) do
    case uploaded_entries(socket, :image) do
      {[_ | _], []} ->
        consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
          event_data =
            Map.merge(
              %{
                "image" => path
              },
              event
            )

          save_event(event_data)
        end)

      _ ->
        save_event(event)
    end

    {:noreply,
     socket
     |> redirect(to: ~p"/events/admin")}
  end

  defp save_event(%{} = event) do
    if String.to_integer(event["id"]) > 0,
      do: EventsTeam.update_event(event),
      else: EventsTeam.create_event(event)
  end
end
