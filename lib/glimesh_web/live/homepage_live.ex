defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts

  @impl true
  def mount(_params, session, socket) do
    maybe_user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])
    {:ok, socket |> assign(:page_title, "Glimesh") |> assign(:current_user, maybe_user) }
  end
end
