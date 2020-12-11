defmodule GlimeshWeb.UserLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  def mount(_, session, socket) do
    users = Accounts.list_users()
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:page_title, "Users")
     |> assign(:users, users)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    users = Accounts.search_users(query)

    {:noreply, assign(socket, users: users, query: query)}
  end
end
