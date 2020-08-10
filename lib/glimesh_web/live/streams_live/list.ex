defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams
  alias Glimesh.Accounts

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:page_title, dgettext("streams", "Followed Streams"))
     |> assign(:category, dgettext("streams", "Followed"))
     |> assign(:show_banner, false)
     |> assign(:streams, Streams.list_followed_streams(user))}
  end

  @impl true
  def mount(params, session, socket) do
    category = String.capitalize(params["category"])
    if session["locale"], do: Gettext.put_locale(session["locale"]) # If the viewer is logged in set their locale, otherwise it defaults to English

    {:ok,
     socket
     |> assign(:page_title, category)
     |> assign(:category, category)
     |> assign(:streams, Streams.list_streams())}
  end
end
