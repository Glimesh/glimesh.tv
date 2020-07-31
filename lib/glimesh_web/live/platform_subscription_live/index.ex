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
        |> assign(:stripe_error, nil)
        |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
        |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
        |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}
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
  def handle_event("cancel-subscription", %{}, socket) do
    user = socket.assigns.user

    # Basically, need to handle the error logic here, we need to rely on server side programming instead of client side crap
    with {:ok, _} <- Glimesh.Payments.cancel_subscription(:platform, user)
      do
      {:noreply, socket |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}
    else
      {:error, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("stripe-create-subscription", %{"paymentMethodId" => payment_method, "priceId" => price_id}, socket) do
    user = socket.assigns.user
    # Basically, need to handle the error logic here, we need to rely on server side programming instead of client side crap
    with {:ok, _} <- Glimesh.Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <- Glimesh.Payments.subscribe(:platform, user, "prod_HhtjnDMhfliLrf", price_id)
      do
        {:reply, subscription, socket |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}
      else
        {:pending_requires_action, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
        {:pending_requires_payment_method, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
        {:error, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  defp list_platform_subscriptions do
    Payments.list_platform_subscriptions()
  end
end
