defmodule GlimeshWeb.PageLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams
  alias Glimesh.Accounts

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok, socket
          |> assign(:page_title, "Followed Streams")
          |> assign(:category, "Followed Streams")
          |> assign(:show_banner, false)
          |> assign(:streams,  Streams.list_followed_streams(user))}
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket
          |> assign(:page_title, params["category"])
          |> assign(:category, params["category"])
          |> assign(:show_banner, is_nil(params["category"]))
          |> assign(:streams,  Streams.list_streams())}
  end

end
