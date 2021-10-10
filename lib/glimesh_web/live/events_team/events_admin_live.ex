defmodule GlimeshWeb.EventsTeam.EventsAdminLive do
  use GlimeshWeb, :live_view

  alias Glimesh.EventsTeam
  alias Glimesh.EventsTeam.Event

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
    changeset = EventsTeam.delete_event(eventid)

    {:noreply,
     socket
     |> redirect(to: Routes.events_admin_path(socket, :index))}
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
     |> redirect(to: Routes.events_admin_path(socket, :index))}
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

  defp save_event(%{} = event) do
    if String.to_integer(event["id"]) > 0,
      do: EventsTeam.update_event(event),
      else: EventsTeam.create_event(event)
  end
end
