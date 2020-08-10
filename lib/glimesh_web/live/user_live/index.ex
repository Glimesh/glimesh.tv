defmodule GlimeshWeb.UserLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  def mount(_, session, socket) do
    users = Accounts.list_users()
    if session["locale"], do: Gettext.put_locale(session["locale"]) # If the viewer is logged in set their locale, otherwise it defaults to English

    {:ok,
         socket
         |> assign(:page_title, "Users")
         |> assign(:users, users)
        }
  end
end
