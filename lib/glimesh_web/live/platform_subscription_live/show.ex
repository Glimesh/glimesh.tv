defmodule GlimeshWeb.PlatformSubscriptionLive.Show do
  use GlimeshWeb, :live_view

  alias Glimesh.Payments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:platform_subscription, Payments.get_platform_subscription!(id))}
  end

  defp page_title(:show), do: "Show Platform subscription"
  defp page_title(:edit), do: "Edit Platform subscription"
end
