defmodule GlimeshWeb.UserLive.SubscribeButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok, socket |> assign(:streamer, streamer) |> assign(:user, nil) |> assign(:subscribed, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    subscribed = false # Glimesh.Streams.is_following?(streamer, user)

    {:ok, socket
          |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
          |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
          |> assign(:stripe_error, nil)
          |> assign(:streamer, streamer)
          |> assign(:user, user)
          |> assign(:subscribed, subscribed)}
  end

  def handle_event("subscribe", value, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user

    case Stripe.PaymentIntent.create(%{
     payment_method_types: ["card"],
     amount: 500,
     currency: "usd",
     application_fee_amount: 250,
     transfer_data: %{
       destination: streamer.stripe_user_id,
     }
    }) do
      {:ok, intent} -> {:noreply, socket |> push_event("accept-payment-intent", %{client_secret: intent.client_secret})}
      {:error, %Stripe.Error{}} -> {:noreply, socket}
    end
  end

  def handle_event("unsubscribe", _value, socket) do
    {:noreply, socket}
  end
end
