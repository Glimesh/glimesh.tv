defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.Payments.Subscription
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel

  def get_platform_sub_supporter_product_id,
    do: get_stripe_config(:platform_sub_supporter_product_id)

  def get_platform_sub_supporter_price_id, do: get_stripe_config(:platform_sub_supporter_price_id)
  def get_platform_sub_supporter_price, do: get_stripe_config(:platform_sub_supporter_price)

  def get_platform_sub_founder_product_id,
    do: get_stripe_config(:platform_sub_founder_product_id)

  def get_platform_sub_founder_price_id, do: get_stripe_config(:platform_sub_founder_price_id)
  def get_platform_sub_founder_price, do: get_stripe_config(:platform_sub_founder_price)

  def get_channel_sub_base_product_id, do: get_stripe_config(:channel_sub_base_product_id)
  def get_channel_sub_base_price_id, do: get_stripe_config(:channel_sub_base_price_id)
  def get_channel_sub_base_price, do: get_stripe_config(:channel_sub_base_price)

  def get_stripe_config(key) do
    Application.get_env(:glimesh, :stripe_config)[key]
  end

  def list_all_subscriptions do
    Repo.all(
      from s in Subscription,
        where: s.is_active == true
    )
    |> Repo.preload([:user, :streamer])
  end

  def list_streamer_subscribers(streamer) do
    Repo.all(
      from s in Subscription,
        where: s.streamer_id == ^streamer.id and s.is_active == true
    )
    |> Repo.preload([:user, :streamer])
  end

  def list_user_subscriptions(user) do
    Repo.all(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and not is_nil(s.streamer_id)
    )
    |> Repo.preload([:user, :streamer])
  end

  def set_payment_method(user, payment_method_id) do
    customer_id = Accounts.get_stripe_customer_id(user)

    with {:ok, _} <-
           Stripe.PaymentMethod.attach(%{customer: customer_id, payment_method: payment_method_id}),
         {:ok, _} <-
           Stripe.Customer.update(customer_id, %{
             invoice_settings: %{default_payment_method: payment_method_id}
           }),
         {:ok, user} <- Accounts.set_stripe_default_payment(user, payment_method_id) do
      {:ok, user}
    else
      {:error, %Stripe.Error{message: message}} ->
        {:error, message}

      {:error, %Stripe.Error{user_message: user_message}} ->
        {:error, user_message}

      {:error, %Ecto.Changeset{errors: errors}} ->
        {:error, errors}
    end
  end

  def subscribe_to_platform(user, product_id, price_id) do
    if has_platform_subscription?(user) do
      raise ArgumentError, "You already have an active subscription to this streamer."
    end

    customer_id = Accounts.get_stripe_customer_id(user)

    stripe_input = %{customer: customer_id, items: [%{price: price_id}]}

    {:ok, product} = Stripe.Product.retrieve(product_id)
    {:ok, price} = Stripe.Price.retrieve(price_id)

    sub_attrs = %{
      user: user,
      stripe_product_id: product_id,
      stripe_price_id: price_id,
      price: price.unit_amount,
      fee: 0,
      payout: price.unit_amount,
      product_name: product.name
    }

    Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"])
    |> handle_stripe_subscription_create(user, sub_attrs)
  end

  def subscribe_to_channel(user, streamer, product_id, price_id) do
    if user.id == streamer.id do
      raise ArgumentError, "You cannot subscribe to yourself."
    end

    if has_channel_subscription?(user, streamer) do
      raise ArgumentError, "You already have an active subscription to this streamer."
    end

    customer_id = Accounts.get_stripe_customer_id(user)

    {:ok, product} = Stripe.Product.retrieve(product_id)
    {:ok, price} = Stripe.Price.retrieve(price_id)

    stripe_input = %{
      customer: customer_id,
      items: [%{price: price_id}],
      application_fee_percent: 50,
      transfer_data: %{destination: streamer.stripe_user_id}
    }

    sub_attrs = %{
      user: user,
      streamer: streamer,
      stripe_product_id: product_id,
      stripe_price_id: price_id,
      price: price.unit_amount,
      fee: trunc(stripe_input.application_fee_percent / 100 * price.unit_amount),
      payout:
        trunc(price.unit_amount - stripe_input.application_fee_percent / 100 * price.unit_amount),
      product_name: product.name
    }

    Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"])
    |> handle_stripe_subscription_create(user, sub_attrs)
  end

  @doc """
  Stripe Test Card Numbers:
    4000 0000 0000 0341 sub.status: "incomplete", sub.latest_invoice.status = "open"
    4242 4242 4242 4242 sub.status: "active", sub.latest_invoice.status = "paid"
    4000 0000 0000 3220 3D Secure
  """
  def handle_stripe_subscription_create({:ok, %Stripe.Subscription{} = sub}, user, sub_attrs) do
    case sub.status do
      "active" ->
        create_subscription(
          Enum.into(sub_attrs, %{
            stripe_subscription_id: sub.id,
            stripe_current_period_end: sub.current_period_end,
            is_active: true,
            started_at: NaiveDateTime.utc_now(),
            ended_at: NaiveDateTime.utc_now()
          })
        )

      "incomplete" ->
        handle_stripe_payment_failure(user, sub)
    end
  end

  def handle_stripe_subscription_create(error, _user, _sub_attrs) do
    case error do
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
      _ -> {:error, "Unexpected error."}
    end
  end

  def handle_stripe_payment_failure(%User{} = user, %Stripe.Subscription{} = sub) do
    case sub.latest_invoice.payment_intent.status do
      "requires_payment_method" ->
        # To resolve these scenarios:
        #
        # Notify the customer, collect new payment information, and create a new payment method
        # Attach the payment method to the customer
        # Update the default payment method
        # Pay the invoice using the new payment method
        error_message =
          Map.get(
            sub.latest_invoice.payment_intent.last_payment_error,
            :message,
            "There was a problem processing your payment. Please try again."
          )

        Accounts.set_stripe_default_payment(user, nil)

        {:error, error_message}

      "requires_action" ->
        # This needs to be handled on the frontend so the user gets another prompt
        # To handle these scenarios:
        #
        # Notify the customer that authentication is required
        # Complete authentication using stripe.ConfirmCardPayment
        # {:pending_requires_action, "requires_action"}

        Accounts.set_stripe_default_payment(user, nil)

        {:error, "3D Secure Cards are not yet supported."}
    end
  end

  def unsubscribe(subscription) do
    with {:ok, _} <- Stripe.Subscription.delete(subscription.stripe_subscription_id),
         {:ok, sub} <- update_subscription(subscription, %{is_active: false}) do
      {:ok, sub}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def process_successful_renewal(stripe_subscription_id, new_expiration_date) do
    case get_subscription_by_stripe_id(stripe_subscription_id) do
      %Subscription{} = sub ->
        update_subscription(sub, %{
          is_active: true,
          ended_at: new_expiration_date |> DateTime.from_unix!() |> DateTime.to_naive()
        })

      _ ->
        {:error, "Unable to find subscription by stripe_subscription_id"}
    end
  end

  def process_unsuccessful_renewal(stripe_subscription_id) do
    case get_subscription_by_stripe_id(stripe_subscription_id) do
      %Subscription{} = sub ->
        unsubscribe(sub)

      _ ->
        {:error, "Unable to find subscription by stripe_subscription_id"}
    end
  end

  def get_subscription_by_stripe_id(subscription_id) when is_binary(subscription_id) do
    Repo.one(
      from s in Subscription,
        where: s.stripe_subscription_id == ^subscription_id
    )
  end

  def get_subscription_by_stripe_id(nil), do: nil

  def get_platform_subscription!(user) do
    Repo.one(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and is_nil(s.streamer_id)
    )
    |> Repo.preload(:user)
  end

  def has_platform_subscription?(user) do
    Repo.exists?(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and is_nil(s.streamer_id)
    )
  end

  def is_platform_supporter_subscriber?(user) do
    Repo.exists?(
      from s in Subscription,
        where:
          s.user_id == ^user.id and
            s.is_active == true and
            is_nil(s.streamer_id) and
            s.stripe_product_id == ^get_platform_sub_supporter_product_id()
    )
  end

  def is_platform_founder_subscriber?(user) do
    Repo.exists?(
      from s in Subscription,
        where:
          s.user_id == ^user.id and
            s.is_active == true and
            is_nil(s.streamer_id) and
            s.stripe_product_id == ^get_platform_sub_founder_product_id()
    )
  end

  def get_channel_subscriptions(user) do
    Repo.all(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and not is_nil(s.streamer_id)
    )
    |> Repo.preload([:user, :streamer])
  end

  def get_channel_subscription!(user, streamer) do
    Repo.get_by!(Subscription, user_id: user.id, is_active: true, streamer_id: streamer.id)
    |> Repo.preload([:user, :streamer])
  end

  def has_channel_subscription?(user, streamer) do
    Repo.exists?(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and s.streamer_id == ^streamer.id
    )
  end

  def is_subscribed?(%Channel{} = channel, %User{} = user) do
    Repo.exists?(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and s.streamer_id == ^channel.user_id
    )
  end

  def list_platform_founder_subscribers do
    Repo.all(
      from s in Subscription,
        where:
          s.is_active == true and is_nil(s.streamer_id) and
            s.stripe_product_id == ^get_platform_sub_founder_product_id()
    )
    |> Repo.preload(:user)
  end

  def list_platform_supporter_subscribers do
    Repo.all(
      from s in Subscription,
        where:
          s.is_active == true and is_nil(s.streamer_id) and
            s.stripe_product_id == ^get_platform_sub_supporter_product_id()
    )
    |> Repo.preload(:user)
  end

  def oauth_connect(user, code) do
    with {:ok, resp} <- Stripe.Connect.OAuth.token(code),
         {:ok, _} <- Accounts.set_stripe_user_id(user, resp.stripe_user_id) do
      {:ok, "Successfully updated Stripe oauth user."}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def get_stripe_dashboard_url(%User{stripe_user_id: nil}), do: nil

  def get_stripe_dashboard_url(%User{stripe_user_id: stripe_user_id}) do
    case Stripe.Account.create_login_link(stripe_user_id, %{}) do
      {:ok, %Stripe.LoginLink{url: stripe_dashboard_url}} -> stripe_dashboard_url
      {:error, _} -> nil
    end
  end

  def sum_incoming(user) do
    Repo.one(
      from s in Subscription,
        select: sum(s.payout),
        where: s.streamer_id == ^user.id and s.is_active == true
    )
  end

  def sum_outgoing(user) do
    Repo.one(
      from s in Subscription,
        select: sum(s.price),
        where: s.user_id == ^user.id and s.is_active == true
    )
  end

  def list_payment_history(%User{stripe_customer_id: nil}), do: []

  def list_payment_history(%User{stripe_customer_id: stripe_customer_id}) do
    {:ok, payment_history} = Stripe.Charge.list(%{customer: stripe_customer_id})

    payment_history.data
  end

  def list_payout_history(%User{stripe_user_id: nil}), do: []

  def list_payout_history(%User{stripe_user_id: stripe_user_id}) do
    {:ok, payout_history} = Stripe.Transfer.list(%{destination: stripe_user_id})

    payout_history.data
  end

  @doc """
  Returns the list of subscription.

  ## Examples

      iex> list_subscription()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.create_changeset(subscription, attrs)
  end
end
