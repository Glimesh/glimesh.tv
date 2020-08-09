defmodule GlimeshWeb.SubscriptionComponent do
  use GlimeshWeb, :live_component

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
      <form id="subscription-form"
        phx-hook="ProcessPayment"
        data-stripe-public-key="<%= @stripe_public_key %>"
        data-stripe-customer-id="<%= @stripe_customer_id %>"
        data-stripe-payment-method="<%= @stripe_payment_method %>">
          <%= if @stripe_payment_method do %>
            <p>Payment method already attached!</p>
          <% else %>
            <div class="form-group">
              <label for="paymentName">Your Name</label>
              <input id="paymentName" name="name" placeholder="Name on Your Card" required class="form-control">
            </div>
            <div class="form-group">
              <label for="card-element">Payment Details</label>
              <div id="card-element" class="form-control">
              <!-- Elements will create input elements here -->
              </div>
            </div>
          <% end %>

          <%= if @stripe_error do %>
            <div class="alert alert-danger" role="alert">
              <%= @stripe_error %>
            </div>
          <% end %>

          <h4>Total Charge</h4>
            <div class="pricing-plan-label billed-monthly-label">
            <strong>$5</strong>/ monthly
          </div>

          <div id="card-errors" role="alert"></div>

          <button type="submit" class="btn btn-primary btn-block btn-lg">Subscribe</button>
      </form>
    """
  end

  @impl true
  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
      |> assign(:stripe_customer_id, nil)
      |> assign(:stripe_payment_method, nil)
      |> assign(:stripe_error, nil)
    }
  end

  def update(%{type: :platform, user: user} = params, socket) do
    {
      :ok,
      socket
      |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
      |> assign(:stripe_payment_method, user.stripe_payment_method)
    }
  end

  def update(%{type: :channel, user: user, streamer: streamer} = params, socket) do
    {
      :ok,
      socket
      |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
      |> assign(:stripe_payment_method, user.stripe_payment_method)
    }
  end

  def base_update(params, socket) do
    socket |> assign(:productid)
  end

  def handle_event("update_price", %{"product_id" => product_id, "price_id" => price_id}, socket) do
    #    send self(), {:updated_card, %{socket.assigns.card | title: title}}
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "subscriptions.channel.subscribe",
        %{"paymentMethodId" => payment_method, "priceId" => price_id},
        socket
      ) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user

    with {:ok, _} <- Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <-
           Payments.subscribe(:channel, user, streamer, "prod_HhtjnDMhfliLrf", price_id) do
      {:reply, subscription,
       socket
       |> assign(:show_subscription, false)
       |> assign(
         :subscribed,
         Payments.has_channel_subscription?(socket.assigns.user, socket.assigns.streamer)
       )}
    else
      {:pending_requires_action, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}

      {:pending_requires_payment_method, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}

      {:error, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end
end
