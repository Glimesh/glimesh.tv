defmodule GlimeshWeb.PlatformSubscriptionLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Payments
  alias Glimesh.Payments.PlatformSubscription

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :platform_subscriptions, list_platform_subscriptions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Platform subscription")
    |> assign(:platform_subscription, Payments.get_platform_subscription!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Platform subscription")
    |> assign(:platform_subscription, %PlatformSubscription{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Platform subscriptions")
    |> assign(:platform_subscription, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    platform_subscription = Payments.get_platform_subscription!(id)
    {:ok, _} = Payments.delete_platform_subscription(platform_subscription)

    {:noreply, assign(socket, :platform_subscriptions, list_platform_subscriptions())}
  end

  defp list_platform_subscriptions do
    Payments.list_platform_subscriptions()
  end
end
