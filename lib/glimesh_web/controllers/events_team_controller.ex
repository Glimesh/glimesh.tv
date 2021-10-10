defmodule GlimeshWeb.EventsTeamController do
  use GlimeshWeb, :controller

  def events_team(conn, _param) do
    featured_events = Glimesh.EventsTeam.list_featured_events()

    render(conn, "events_team.html",
      page_title: format_page_title(gettext("Events")),
      featured: featured_events
    )
  end
end
