defmodule GlimeshWeb.UserLive.Followers do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  def mount(%{"username" => username}, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = streamer ->
        followers = Glimesh.AccountFollows.list_followers(streamer)

        {:ok,
         socket
         |> assign(:streamer, streamer)
         |> assign(:users, followers)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
