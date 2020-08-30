defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts
  alias Glimesh.Payments.Subscription
  alias Glimesh.Repo

  def get_platform_sub_supporter_product_id,
    do: get_stripe_config(:platform_sub_supporter_product_id)

  def get_platform_sub_supporter_price_id, do: get_stripe_config(:platform_sub_supporter_price_id)
  def get_platform_sub_supporter_price, do: get_stripe_config(:platform_sub_supporter_price)

  def get_platform_sub_founder_product_id,
    do: get_stripe_config(:platform_sub_founder_product_id)

  def get_platform_sub_founder_price_id, do: get_stripe_config(:platform_sub_founder_price_id)
  def get_platform_sub_founder_price, do: get_stripe_config(:platform_sub_founder_price)

  def get_channel_sub_base_product_id, do: get_stripe_config(:platform_sub_supporter_product_id)
  def get_channel_sub_base_price_id, do: get_stripe_config(:platform_sub_supporter_price_id)
  def get_channel_sub_base_price, do: get_stripe_config(:platform_sub_supporter_price)

  def get_stripe_config(key) do
    Application.get_env(:glimesh, :stripe_config)[key]
  end

  def set_payment_method(user, payment_method_id) do
    customer_id = Accounts.get_stripe_customer_id(user)

    with {:ok, _} <-
           Stripe.PaymentMethod.attach(%{customer: customer_id, payment_method: payment_method_id}),
         {:ok, _} <-
           Stripe.Customer.update(customer_id, %{
             invoice_settings: %{default_payment_method: payment_method_id}
           }),
         {:ok, _} <- Accounts.set_stripe_default_payment(user, payment_method_id) do
      {:ok, "Successfully saved and set payment method as default."}
    else
      {:error, %Stripe.Error{user_message: user_message}} -> {:error, user_message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def subscribe(:platform, user, product_id, price_id) do
    customer_id = Accounts.get_stripe_customer_id(user)

    stripe_input = %{customer: customer_id, items: [%{price: price_id}]}

    with {:ok, sub} <-
           Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"]),
         {:ok, platform_sub} <-
           create_subscription(%{
             user: user,
             stripe_subscription_id: sub.id,
             stripe_product_id: product_id,
             stripe_price_id: price_id,
             stripe_current_period_end: sub.current_period_end,
             is_active: true,
             started_at: NaiveDateTime.utc_now(),
             ended_at: NaiveDateTime.utc_now()
           }) do
      {:ok, platform_sub}
    else
      {:error, %Stripe.Error{user_message: user_message}} -> {:error, user_message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def subscribe(:channel, user, streamer, product_id, price_id) do
    # Basically the same as subscribe(:platform) but with
    # "transfer_data" => [
    #    "destination" => "{{CONNECTED_STRIPE_ACCOUNT_ID}}",
    #  ],
    # "application_fee_percent" => 10,
    customer_id = Accounts.get_stripe_customer_id(user)

    stripe_input = %{
      customer: customer_id,
      items: [%{price: price_id}],
      application_fee_percent: 50,
      transfer_data: %{destination: streamer.stripe_user_id}
    }

    with {:ok, stripe_sub} <-
           Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"]),
         {:ok, channel_sub} <-
           create_subscription(%{
             user: user,
             streamer: streamer,
             stripe_subscription_id: stripe_sub.id,
             stripe_product_id: product_id,
             stripe_price_id: price_id,
             stripe_current_period_end: stripe_sub.current_period_end,
             is_active: true,
             started_at: NaiveDateTime.utc_now(),
             ended_at: NaiveDateTime.utc_now()
           }) do
      {:ok,
       %{
         status: stripe_sub.status,
         subscription: channel_sub
       }}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def unsubscribe(subscription) do
    with {:ok, _} <- Stripe.Subscription.delete(subscription.stripe_subscription_id),
         {:ok, platform_sub} <- update_subscription(subscription, %{is_active: false}) do
      {:ok, platform_sub}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

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

  def oauth_connect(user, code) do
    with {:ok, resp} <- Stripe.Connect.OAuth.token(code),
         {:ok, _} <- Accounts.set_stripe_user_id(user, resp.stripe_user_id) do
      {:ok, "Successfully updated Stripe oauth user."}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
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
