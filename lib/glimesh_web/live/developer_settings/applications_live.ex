defmodule GlimeshWeb.DeveloperSettings.ApplicationsLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""

    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_page_title(gettext("Applications"))}
  end
end
