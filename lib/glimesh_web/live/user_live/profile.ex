defmodule GlimeshWeb.UserLive.Profile do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_by_username(username) do
      %Glimesh.Accounts.User{} = user ->
        {:ok, socket
              |> assign(:page_title, "#{user.displayname}'s Profile")
              |> assign(:user, user)
        }

      nil -> {:ok, redirect(socket, to: "/")}
    end

  end

end
