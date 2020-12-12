defmodule GlimeshWeb.UserLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @impl true
  def mount(_, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:page_title, "Users")
     |> assign(page: 1, per_page: 12, update_mode: "append")
     |> search_users(), temporary_assigns: [users: []]}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     assign(socket, update_mode: "replace", page: 1, per_page: 12, query: query) |> search_users()}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, update_mode: "append", page: assigns.page + 1) |> search_users()}
  end

  def search_users(%{assigns: %{query: query, page: page, per_page: per}} = socket) do
    assign(socket, users: Accounts.search_users(query, page, per))
  end
end
