defmodule GlimeshWeb.StreamsLive.Following do
  use GlimeshWeb, :live_view

  alias Glimesh.AccountFollows
  alias Glimesh.Accounts

  @impl true
  def mount(_params, session, socket) do
    case Accounts.get_user_by_session_token(session["user_token"]) do
      %Glimesh.Accounts.User{} = user ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        live_streams = Glimesh.ChannelLookups.list_live_followed_channels_and_hosts(user)

        {:ok,
         socket
         |> put_page_title(gettext("Followed Streams"))
         |> assign(:query, "")
         |> assign(page: 1, per_page: 12, update_mode: "append")
         |> assign(:current_user, user)
         |> search_followed_users()
         |> assign(:channels, live_streams), temporary_assigns: [users: []]}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     assign(socket, update_mode: "replace", page: 1, per_page: 12, query: query)
     |> search_followed_users()}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply,
     assign(socket, update_mode: "append", page: assigns.page + 1) |> search_followed_users()}
  end

  def search_followed_users(%{assigns: %{query: query, page: page, per_page: per}} = socket) do
    user = socket.assigns.current_user
    assign(socket, users: AccountFollows.search_following(user, query, page, per))
  end
end
