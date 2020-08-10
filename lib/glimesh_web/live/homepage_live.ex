defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"]) # If the viewer is logged in set their locale, otherwise it defaults to English
    {:ok, socket}
  end
end
