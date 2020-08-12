defmodule GlimeshWeb.UserLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  def mount(_, session, socket) do
    users = Accounts.list_users()
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:page_title, "Users")
     |> assign(:users, users)}
  end
end
