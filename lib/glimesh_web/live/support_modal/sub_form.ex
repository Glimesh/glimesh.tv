defmodule GlimeshWeb.SupportModal.SubForm do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <div>
    <%= if @subscribed do %>
      <%= if @canceling do %>
      <h5><%= gettext("Resubscribe") %></h5>
      <%= if @stripe_error do %>
        <div class="alert alert-danger" role="alert">
          <%= @stripe_error %>
        </div>
      <% end %>

      <p><%= gettext("Your subscription is currently set to automatically cancel on %{date}.", date: format_datetime(@subscription.ended_at)) %></p>
      <p><%= gettext("You can resubscribe by clicking the button below, and your subscription will be renewed until you cancel it.") %></p>

      <button class="btn btn-primary btn-block btn-lg" phx-click="resubscribe" phx-throttle="5000"><%= gettext("Resubscribe") %></button>
      <% else %>
      <h4><%= gettext("You're subscribed!") %></h4>
      <p><%= gettext("Thanks for supporting %{streamer}. Your genuine support is appreciated.", streamer: @streamer.displayname) %></p>
      <div class="text-center mt-4">
          <h4>Channel Subscription<br>
          <small><strong>$<%= format_price(@subscription.price) %></strong> /
              <%= gettext("monthly") %></small></h4>
      </div>

      <button class="btn btn-danger btn-block mt-4" phx-click="unsubscribe" phx-throttle="1000"><%= gettext("Cancel Subscription") %></button>
      <% end %>
    <% else %>
      <%= if @user do %>
        <h5><%= gettext("Your Payment Information") %></h5>
        <%= if @stripe_error do %>
          <div class="alert alert-danger" role="alert">
            <%= @stripe_error %>
          </div>
        <% end %>

        <%= live_component @socket, GlimeshWeb.SubscriptionComponent, id: "subscription-component", type: :channel, user: @user, streamer: @streamer, product_id: @product_id, price_id: @price_id, price: @price %>
        <% else %>
        <h4 class="mt-4"><%= gettext("What is Glimesh?") %></h4>
        <p class="">
            <%= gettext("People first streaming, with discoverability as a primary feature. Let's build the next
            generation of streaming.") %> <%= link gettext("Learn More"), to: Routes.about_path(@socket, :faq), target: "_blank" %>
        </p>
        <%= link gettext("Register"), class: "btn btn-primary btn-block mt-4", to: Routes.user_registration_path(@socket, :new), target: "_blank" %>
        <p class="mt-2 text-center">or <%= link gettext("Log in"), class: "", to: Routes.user_session_path(@socket, :new), target: "_blank" %></p>
      <% end %>
    <% end %>
    </div>
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
     |> assign(:canceling, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    subscription = Glimesh.Payments.get_channel_subscription(user, streamer)

    can_subscribe = if Accounts.can_use_payments?(user), do: user.id != streamer.id, else: false
    can_receive_payments = Accounts.can_receive_payments?(streamer)
    subscribed = !is_nil(subscription)

    {:ok,
     socket
     |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
     |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
     |> assign(:stripe_payment_method, user.stripe_payment_method)
     |> assign(:stripe_error, nil)
     |> assign(:product_id, Payments.get_channel_sub_base_product_id())
     |> assign(:price_id, Payments.get_channel_sub_base_price_id())
     |> assign(:price, Payments.get_channel_sub_base_price())
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:can_subscribe, can_subscribe && can_receive_payments && Glimesh.has_launched?())
     |> assign(:canceling, if(subscription, do: subscription.is_canceling, else: false))
     |> assign(:subscription, subscription)
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
end
