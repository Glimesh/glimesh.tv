defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams
  alias Glimesh.Accounts

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:page_title, "Followed Streams")
     |> assign(:category, "Followed Streams")
     |> assign(:show_banner, false)
     |> assign(:streams, Streams.list_followed_streams(user))}
  end

  @impl true
  def mount(params, _session, socket) do
    category = String.capitalize(params["category"])

    {:ok,
     socket
     |> assign(:page_title, category)
     |> assign(:category, category)
     |> assign(:streams, Streams.list_streams())}
  end
end
