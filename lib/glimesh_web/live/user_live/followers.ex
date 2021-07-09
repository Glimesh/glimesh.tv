defmodule GlimeshWeb.UserLive.Followers do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  def mount(%{"username" => username}, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        {:ok,
         socket
         |> assign(:streamer, streamer)
         |> assign(:query, "")
         |> assign(page: 1, per_page: 12, update_mode: "append")
         |> handle_page(), temporary_assigns: [users: []]}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_page(%{assigns: %{live_action: :followers, streamer: streamer}} = socket) do
    socket
    |> assign(:page_title, gettext("%{username}'s Followers", username: streamer.displayname))
    |> load_followers()
  end

  def handle_page(%{assigns: %{live_action: :following, streamer: streamer}} = socket) do
    socket
    |> assign(:page_title, gettext("%{username}'s Following", username: streamer.displayname))
    |> load_following()
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, update_mode: "append", page: assigns.page + 1) |> handle_page()}
  end

  def load_following(
        %{assigns: %{streamer: streamer, query: query, page: page, per_page: per}} = socket
      ) do
    assign(socket,
      users: Glimesh.AccountFollows.list_following_with_scroll(streamer, query, page, per)
    )
  end

  def load_followers(
        %{assigns: %{streamer: streamer, query: query, page: page, per_page: per}} = socket
      ) do
    assign(socket,
      users: Glimesh.AccountFollows.list_follower_with_scroll(streamer, query, page, per)
    )
  end
end
