defmodule GlimeshWeb.UserLive.SubscribeButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok, socket |> assign(:streamer, streamer) |> assign(:user, nil) |> assign(:subscribed, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    subscribed = Glimesh.Payments.has_channel_subscription?(user, streamer)

    {:ok, socket
          |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
          |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
          |> assign(:stripe_payment_method, user.stripe_payment_method)
          |> assign(:stripe_error, nil)
          |> assign(:show_subscription, false)
          |> assign(:streamer, streamer)
          |> assign(:user, user)
          |> assign(:subscribed, subscribed)}
  end

  @impl true
  def handle_event("subscriptions.subscribe", %{"paymentMethodId" => payment_method, "priceId" => price_id}, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user

    with {:ok, _} <- Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <- Payments.subscribe(:channel, user, streamer, "prod_HhtjnDMhfliLrf", price_id)
      do
      {:reply, subscription, socket
                             |> assign(:show_subscription, false)
                             |> assign(:subscribed, Payments.has_channel_subscription?(socket.assigns.user, socket.assigns.streamer))}
    else
      {:pending_requires_action, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
      {:pending_requires_payment_method, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
      {:error, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("unsubscribe", _value, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user
    subscription = Payments.get_channel_subscription!(user, streamer)

    with {:ok, _} <- Payments.unsubscribe(subscription)
      do
      {:noreply, socket |> assign(:subscribed, Payments.has_channel_subscription?(user, streamer))}
    else
      {:error, error_msg} -> {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @implt true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_subscription, true)}
  end

  @implt true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_subscription, false)}
  end

end
