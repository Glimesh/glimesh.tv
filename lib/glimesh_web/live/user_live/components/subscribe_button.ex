defmodule GlimeshWeb.UserLive.Components.SubscribeButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <span id="subscription-magic">
        <%= if @user do %>
            <%= if @can_subscribe do %>
                <%= if @subscribed do %>
                    <%= if @canceling do %>
                    <button class="btn btn-secondary btn-responsive" phx-click="show_resub_modal" phx-throttle="5000"><span class="d-none d-lg-block"><%= gettext("Resubscribe") %></span><span class="d-lg-none"><i class="fas fa-star fa-fw"></i></span></button>
                    <% else %>
                    <button class="btn btn-secondary btn-responsive" phx-click="unsubscribe" phx-throttle="5000" data-confirm="<%= gettext("Are you sure you want to unsubscribe?") %>"><span class="d-none d-lg-block"><%= gettext("Unsubscribe") %></span><span class="d-lg-none"><i class="fas fa-star fa-fw"></i></span></button>
                    <% end %>
                <% else %>
                    <button class="btn btn-secondary btn-responsive" phx-click="show_modal" phx-throttle="5000"><span class="d-none d-lg-block"><%= gettext("Subscribe") %></span><span class="d-lg-none"><i class="fas fa-star fa-fw"></i></span></button>
                <% end %>
            <% else %>
                <button class="btn btn-secondary btn-responsive disabled" data-toggle="tooltip" data-placement="bottom" title="<%= gettext("You cannot subscribe to this user.")%>"><span class="d-none d-lg-block"><%= gettext("Subscribe") %></span><span class="d-lg-none"><i class="fas fa-star fa-fw"></i></span></button>
            <% end %>
        <% else %>
          <span class="d-none d-lg-block"><%= link gettext("Subscribe"), to: Routes.user_registration_path(@socket, :new), class: "btn btn-secondary btn-responsive" %></span>
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

                        <%= live_component GlimeshWeb.SubscriptionComponent, id: "subscription-component", type: :channel, user: @user, streamer: @streamer, product_id: @product_id, price_id: @price_id, price: @price %>
                        <img src="/images/stripe-badge-white.png" alt="We use Stripe as our payment provider."
                        class="img-fluid mt-4 mx-auto d-block">
                    </div>

                </div>
            </div>
        </div>
        <% end %>
        <%= if @show_resub_modal do %>
        <div id="resubModal" class="live-modal"
            phx-capture-click="hide_resub_modal"
            phx-window-keydown="hide_resub_modal"
            phx-key="escape"
            phx-target="#resubModal"
            phx-page-loading>
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title"><%= gettext("Resubscribe") %></h5>
                        <button type="button" class="close" phx-click="hide_resub_modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body">
                        <%= if @stripe_error do %>
                          <div class="alert alert-danger" role="alert">
                            <%= @stripe_error %>
                          </div>
                        <% end %>

                        <p><%= gettext("Your subscription is currently set to automatically cancel at the end of your billing cycle.") %></p>
                        <p><%= gettext("You can resubscribe by clicking the button below, and your subscription will be renewed until you cancel it.") %></p>

                        <button class="btn btn-primary btn-block btn-lg" phx-click="resubscribe" phx-throttle="5000"><%= gettext("Resubscribe") %></button>

                        <img src="/images/stripe-badge-white.png" alt="We use Stripe as our payment provider."
                        class="img-fluid mt-4 mx-auto d-block">
                    </div>

                </div>
            </div>
        </div>
        <% end %>
    </span>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:can_subscribe, false)
     |> assign(:user, nil)
     |> assign(:subscribed, false)
     |> assign(:canceling, false)
     |> assign(:show_resub_modal, false)
     |> assign(:show_subscription, false)}
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
     |> assign(:show_subscription, false)
     |> assign(:show_resub_modal, false)
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:can_subscribe, can_subscribe && can_receive_payments && Glimesh.has_launched?())
     |> assign(:canceling, if(subscription, do: subscription.is_canceling, else: false))
     |> assign(:subscribed, !is_nil(subscription))}
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
        {:noreply, socket |> assign(:canceling, true)}

      {:error, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("resubscribe", _value, socket) do
    streamer = socket.assigns.streamer
    user = socket.assigns.user
    subscription = Payments.get_channel_subscription!(user, streamer)

    case Payments.resubscribe(subscription) do
      {:ok, _} ->
        {:noreply, socket |> assign(:show_resub_modal, false) |> assign(:canceling, false)}

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

  @impl true
  def handle_event("show_resub_modal", _value, socket) do
    {:noreply, socket |> assign(:show_resub_modal, true)}
  end

  @impl true
  def handle_event("hide_resub_modal", _value, socket) do
    {:noreply, socket |> assign(:show_resub_modal, false)}
  end
end
