defmodule GlimeshWeb.UserLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  def mount(_, session, socket) do
    users = Accounts.list_users()

    {:ok,
         socket
         |> assign(:page_title, "Users")
         |> assign(:users, users)
        }
  end
end
