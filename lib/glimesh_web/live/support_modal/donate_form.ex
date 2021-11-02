defmodule GlimeshWeb.SupportModal.DonateForm do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <h5><%= gettext("Your Payment Information") %></h5>
      <%= if @stripe_error do %>
        <div class="alert alert-danger" role="alert">
          <%= @stripe_error %>
        </div>
      <% end %>

      <form id="subscription-form"
        phx-hook="ProcessPayment"
        phx-change="change_amount"
        data-stripe-public-key="<%= @stripe_public_key %>"
        data-stripe-customer-id="<%= @stripe_customer_id %>"
        data-stripe-payment-method="<%= @stripe_payment_method %>">
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

          <div class="form-group">
            <label for="donationAmount"><%= gettext("Amount") %></label>
            <div class="input-group">
              <div class="input-group-prepend">
                <span class="input-group-text">$</span>
              </div>
              <input id="donationAmount" name="amount" type="number" min="1" step="any" value="<%= float_to_binary(@amount) %>"  placeholder="5.00" required class="form-control">
            </div>
          </div>
          <p>Streamer will receive about $<%= float_to_binary(@streamer_amount) %></p>

          <div id="card-errors" role="alert"></div>

          <div class="text-center">
            <div class="show-on-loading spinner-border mb-4" style="width: 3rem; height: 3rem;" role="status">
              <span class="sr-only">Loading...</span>
            </div>
          </div>

          <button type="submit" class="btn btn-primary btn-block btn-lg"><%= gettext("Donate") %></button>
      </form>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    session =
      Stripe.Session.create(%{
        "cancel_url" => "https://glimesh.dev/clone1018",
        "success_url" => "https://glimesh.dev/clone1018",
        "mode" => "payment",
        "payment_method_types" => [
          "card"
        ],
        "submit_type" => "donate",
        "customer" => Accounts.get_stripe_customer_id(user),
        "line_items" => [
          %{
            "description" => "Donation for the users channel",
            "quantity" => 1,
            "price_data" => %{
              "product" => "prod_KWQlLJ3VOjLZVN",
              "currency" => "USD",
              "unit_amount" => 500
            }
          }
        ]
      })

    IO.inspect(session)

    {:ok,
     socket
     |> assign(:amount, 5.00)
     |> assign(:streamer_amount, calculate_streamer_amount(5.00))
     |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
     |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
     |> assign(:stripe_payment_method, user.stripe_payment_method)
     |> assign(:stripe_error, nil)
     |> assign(:streamer, streamer)
     |> assign(:user, user)}
  end

  @impl true
  def handle_event("subscriptions.subscribe", %{"paymentMethodId" => payment_method}, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user
    amount_in_cents = trunc(socket.assigns.amount * 100)
    IO.inspect(amount_in_cents, label: "amount_in_cents")

    with {:ok, user} <- Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <-
           Payments.donate_to_channel(
             user,
             streamer,
             user.stripe_payment_method,
             amount_in_cents
           ) do
      {:reply, %{}, socket}
    else
      {:error, error_msg} ->
        {:noreply,
         socket |> assign(:user, Accounts.get_user!(user.id)) |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("change_amount", %{"amount" => amount}, socket) when is_binary(amount) do
    streamer_amount =
      case Float.parse(amount) do
        {amount, _rem} ->
          calculate_streamer_amount(amount)

        _ ->
          0.00
      end

    {:noreply, socket |> assign(:streamer_amount, streamer_amount)}
  end

  def handle_event("change_amount", _, socket) do
    {:noreply, socket}
  end

  defp calculate_streamer_amount(amount) when is_float(amount) do
    Float.floor(amount - amount * 0.029 - 0.30, 2)
  end

  defp float_to_binary(amount) when is_float(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end

  # @impl true
  # def handle_event("unsubscribe", _value, socket) do
  #   streamer = socket.assigns.streamer
  #   user = socket.assigns.user
  #   subscription = Payments.get_channel_subscription!(user, streamer)

  #   case Payments.unsubscribe(subscription) do
  #     {:ok, _} ->
  #       {:noreply, socket |> assign(:canceling, true)}

  #     {:error, error_msg} ->
  #       {:noreply, socket |> assign(:stripe_error, error_msg)}
  #   end
  # end

  # @impl true
  # def handle_event("resubscribe", _value, socket) do
  #   streamer = socket.assigns.streamer
  #   user = socket.assigns.user
  #   subscription = Payments.get_channel_subscription!(user, streamer)

  #   case Payments.resubscribe(subscription) do
  #     {:ok, _} ->
  #       {:noreply, socket |> assign(:show_resub_modal, false) |> assign(:canceling, false)}

  #     {:error, error_msg} ->
  #       {:noreply, socket |> assign(:stripe_error, error_msg)}
  #   end
  # end
end
