defmodule GlimeshWeb.PlatformSubscriptionLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments
  alias Payments

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:can_payments, Accounts.can_use_payments?(user))
     |> assign(:stripe_error, nil)
     |> assign(:product_id, Payments.get_platform_sub_founder_product_id())
     |> assign(:price_id, Payments.get_platform_sub_founder_price_id())
     |> assign(:price, Payments.get_platform_sub_founder_price())
     |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
     |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
     |> assign(:subscription, Payments.get_platform_subscription!(user))
     |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> put_page_title(gettext("Glimesh Platform Subscriptions"))
    |> assign(:platform_subscription, nil)
  end

  def handle_event("select-platform-supporter", _, socket) do
    {:noreply,
     socket
     |> assign(:product_id, Payments.get_platform_sub_supporter_product_id())
     |> assign(:price_id, Payments.get_platform_sub_supporter_price_id())
     |> assign(:price, Payments.get_platform_sub_supporter_price())}
  end

  def handle_event("select-platform-founder", _, socket) do
    {:noreply,
     socket
     |> assign(:product_id, Payments.get_platform_sub_founder_product_id())
     |> assign(:price_id, Payments.get_platform_sub_founder_price_id())
     |> assign(:price, Payments.get_platform_sub_founder_price())}
  end

  @impl true
  def handle_event(
        "subscriptions.subscribe",
        %{"paymentMethodId" => payment_method},
        socket
      ) do
    user = socket.assigns.user

    with {:ok, _} <- Payments.set_payment_method(user, payment_method),
         {:ok, subscription} <-
           Payments.subscribe_to_platform(
             user,
             socket.assigns.product_id,
             socket.assigns.price_id
           ) do
      {:reply, subscription,
       socket
       |> assign(:show_subscription, false)
       |> assign(:subscription, Payments.get_platform_subscription!(user))
       |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}
    else
      {:pending_requires_action, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}

      {:pending_requires_payment_method, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}

      {:error, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end

  @impl true
  def handle_event("cancel-subscription", %{}, socket) do
    user = socket.assigns.user

    subscription = Payments.get_platform_subscription!(user)

    case Payments.unsubscribe(subscription) do
      {:ok, _} ->
        {:noreply,
         socket |> assign(:has_platform_subscription, Payments.has_platform_subscription?(user))}

      {:error, error_msg} ->
        {:noreply, socket |> assign(:stripe_error, error_msg)}
    end
  end
end
