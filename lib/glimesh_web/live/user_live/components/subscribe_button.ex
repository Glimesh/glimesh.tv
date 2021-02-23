defmodule GlimeshWeb.UserLive.Components.SubscribeButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <div id="subscription-magic">
        <%= if @user do %>
            <%= if @can_subscribe do %>
                <%= if @subscribed do %>
                    <button class="btn btn-secondary btn-responsive" phx-click="unsubscribe" phx-throttle="5000"><span class="d-none d-lg-block"><%= gettext("Unsubscribe") %></span><span class="d-lg-none"><i class="fas fa-star"></i></span></button>
                <% else %>
                    <button class="btn btn-secondary btn-responsive" phx-click="show_modal" phx-throttle="5000"><span class="d-none d-lg-block"><%= gettext("Subscribe") %></span><span class="d-lg-none"><i class="fas fa-star"></i></span></button>
                <% end %>
            <% else %>
                <button class="btn btn-secondary btn-responsive disabled" data-toggle="tooltip" data-placement="bottom" title="Subscriptions are not enabled yet, come back after March 2nd at 11AM to subscribe!"><span class="d-none d-lg-block"><%= gettext("Subscribe") %></span><span class="d-lg-none"><i class="fas fa-star"></i></span></button>
            <% end %>
        <% else %>
          <span class="d-none d-lg-block"><%= link gettext("Subscribe"), to: Routes.user_registration_path(@socket, :new), class: "btn btn-secondary btn-responsive" %></span><span class="d-lg-none"><i class="fas fa-star"></i></span>
        <% end %>

        <%= if @show_subscription do %>
        <div id="paymentModal2" class="live-modal"
            phx-capture-click="hide_modal"
            phx-window-keydown="hide_modal"
            phx-key="escape"
            phx-target="#paymentModal2"
            phx-page-loading>
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title"><%= gettext("Payment Details") %></h5>
                        <button type="button" class="close" phx-click="hide_modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body">
                        <%= if @stripe_error do %>
                          <div class="alert alert-danger" role="alert">
                            <%= @stripe_error %>
                          </div>
                        <% end %>

                        <%= live_component @socket, GlimeshWeb.SubscriptionComponent, id: "subscription-component", type: :channel, user: @user, streamer: @streamer, product_id: @product_id, price_id: @price_id, price: @price %>
                        <img src="/images/stripe-badge-white.png" alt="We use Stripe as our payment provider."
                        class="img-fluid mt-4 mx-auto d-block">
                    </div>

                </div>
            </div>
        </div>
        <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:can_subscribe, false)
     |> assign(:user, nil)
     |> assign(:subscribed, false)
     |> assign(:show_subscription, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    subscribed = Glimesh.Payments.has_channel_subscription?(user, streamer)

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
     |> assign(:show_subscription, false)
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:can_subscribe, can_subscribe && can_receive_payments && Glimesh.has_launched?())
     |> assign(:subscribed, subscribed)}
  end

  @impl true
  def handle_event("subscriptions.subscribe", %{"paymentMethodId" => payment_method}, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user

    with {:ok, user} <- Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <-
           Payments.subscribe_to_channel(
             user,
             streamer,
             socket.assigns.product_id,
             socket.assigns.price_id
           ) do
      {:reply, subscription,
       socket
       |> assign(:user, Accounts.get_user!(user.id))
       |> assign(:show_subscription, false)
       |> assign(
         :subscribed,
         Payments.has_channel_subscription?(socket.assigns.user, socket.assigns.streamer)
       )}
    else
      # {:pending_requires_action, error_msg} ->
      #   {:noreply, socket |> assign(:stripe_error, error_msg)}

      # {:pending_requires_payment_method, error_msg} ->
      #   {:noreply, socket |> assign(:stripe_error, error_msg)}

      {:error, error_msg} ->
        {:noreply,
         socket |> assign(:user, Accounts.get_user!(user.id)) |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("unsubscribe", _value, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user
    subscription = Payments.get_channel_subscription!(user, streamer)

    case Payments.unsubscribe(subscription) do
      {:ok, _} ->
        {:noreply,
         socket |> assign(:subscribed, Payments.has_channel_subscription?(user, streamer))}

      {:error, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_subscription, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_subscription, false)}
  end
end
