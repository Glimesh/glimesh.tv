defmodule GlimeshWeb.SubscriptionComponent do
  use GlimeshWeb, :live_component

  alias Glimesh.Accounts

  @impl true
  def render(assigns) do
    ~L"""
      <form id="subscription-form"
        phx-hook="ProcessPayment"
        data-stripe-public-key="<%= @stripe_public_key %>"
        data-stripe-customer-id="<%= @stripe_customer_id %>"
        data-stripe-payment-method="<%= @stripe_payment_method %>"
        data-stripe-product-id="<%= @stripe_product_id %>"
        data-stripe-price-id="<%= @stripe_price_id %>">
          <%= if @stripe_payment_method do %>
            <p><%= gettext("Payment method already attached!") %> </p>
          <% else %>
            <div id="subscription-form-ignore" phx-update="ignore">
            <div class="form-group">
              <label for="paymentName"><%= gettext("Your Name") %></label>
              <input id="paymentName" name="name" placeholder="Name on Your Card" required class="form-control">
            </div>
            <div class="form-group">
              <label for="card-element"><%= gettext("Payment Details") %></label>
              <div id="card-element" class="form-control">
              <!-- Elements will create input elements here -->
              </div>
            </div>
            </div>
          <% end %>

          <%= if @stripe_error do %>
            <div class="alert alert-danger" role="alert">
              <%= @stripe_error %>
            </div>
          <% end %>

          <h4><%= gettext("Total Charge") %></h4>
            <div class="pricing-plan-label billed-monthly-label">
            <strong>$<%= @price %></strong>/ <%= gettext("monthly") %>
          </div>

          <div id="card-errors" role="alert"></div>

          <button type="submit" class="btn btn-primary btn-block btn-lg"><%= gettext("Subscribe") %></button>
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

  @impl true
  def update(%{user: user} = data, socket) do
    {
      :ok,
      socket
      |> assign(:stripe_product_id, data.product_id)
      |> assign(:stripe_price_id, data.price_id)
      |> assign(:price, format_price(data.price))
      |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
      |> assign(:stripe_payment_method, user.stripe_payment_method)
    }
  end

  defp format_price(iprice) do
    :erlang.float_to_binary(iprice / 100, decimals: 2)
  end
end
