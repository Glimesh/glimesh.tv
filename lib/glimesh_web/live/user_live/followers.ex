defmodule GlimeshWeb.UserLive.Followers do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Repo

  def mount(%{"username" => username}, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        {:ok,
         socket
         |> assign(:streamer, streamer)
         |> handle_page()}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_page(%{assigns: %{live_action: :followers, streamer: streamer}} = socket) do
    socket
    |> assign(:page_title, gettext("%{username}'s Followers", username: streamer.displayname))
    |> assign(:users, Glimesh.AccountFollows.list_followers(streamer))
  end

  def handle_page(%{assigns: %{live_action: :following, streamer: streamer}} = socket) do
    socket
    |> assign(:page_title, gettext("%{username}'s Following", username: streamer.displayname))
    |> assign(:users, Repo.all(Glimesh.AccountFollows.list_following(streamer)))
  end
end
