defmodule GlimeshWeb.SupportModal.GiftSubForm do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <h5>Gift Subscription</h5>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    subscription = Glimesh.Payments.get_channel_subscription(user, streamer)

    can_subscribe = if Accounts.can_use_payments?(user), do: user.id != streamer.id, else: false
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    {:ok,
     socket
     |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
     |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
     |> assign(:stripe_payment_method, user.stripe_payment_method)
     |> assign(:stripe_error, nil)
     |> assign(:product_id, Payments.get_channel_sub_base_product_id())
     |> assign(:price_id, Payments.get_channel_sub_base_price_id())
     |> assign(:price, Payments.get_channel_sub_base_price())
     |> assign(:show_subscription, true)
     |> assign(:show_resub_modal, false)
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:can_subscribe, can_subscribe && can_receive_payments && Glimesh.has_launched?())
     |> assign(:canceling, if(subscription, do: subscription.is_canceling, else: false))
     |> assign(:subscribed, !is_nil(subscription))}
  end
end
