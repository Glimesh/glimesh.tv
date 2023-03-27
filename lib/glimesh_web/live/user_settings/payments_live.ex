defmodule GlimeshWeb.UserSettings.PaymentsLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/payments"}>
      <:title><%= gettext("Payments") %></:title>
    </Settings.page>
    """
  end

  def mount(_, _, socket) do
    {:ok, socket |> put_page_title(gettext("Payments"))}
  end
end
