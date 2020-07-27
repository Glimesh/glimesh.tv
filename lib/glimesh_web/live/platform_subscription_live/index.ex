defmodule GlimeshWeb.PlatformSubscriptionLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Payments
  alias Glimesh.Accounts
  alias Glimesh.Payments.PlatformSubscription

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok, socket
        |> assign(:user, user)
        |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
        |> assign(:platform_subscriptions, list_platform_subscriptions())}
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

  @impl true
  def handle_event("stripe-create-subscription", %{"paymentMethodId" => payment_method, "priceId" => price_id}, socket) do
    :ok = Glimesh.Payments.set_payment_method(socket.assigns.user, payment_method)
    :ok = Glimesh.Payments.subscribe(:platform, socket.assigns.user, "prod_HhtjnDMhfliLrf", price_id)

    {:reply, socket}
  end

  defp list_platform_subscriptions do
    Payments.list_platform_subscriptions()
  end
end
