defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Payments.PlatformSubscription

  def set_payment_method(user, payment_method_id) do
    customer_id = Glimesh.Accounts.get_stripe_customer_id(user)

    with {:ok, _} <- Stripe.PaymentMethod.attach(%{customer: customer_id, payment_method: payment_method_id}),
         {:ok, _} = Stripe.Customer.update(
           customer_id,
           %{invoice_settings: %{default_payment_method: payment_method_id}}
         )
      do
      {:ok, "Successfully saved and set payment method as default."}
    else
      {:error, %Stripe.Error{user_message: user_message}} -> {:error, user_message}
    end
  end

  def subscribe(:platform, user, product_id, price_id) do
    customer_id = Glimesh.Accounts.get_stripe_customer_id(user)

    stripe_input = %{ customer: customer_id, items: [%{ price: price_id }] }

    with {:ok, sub} <- Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"]),
         {:ok, platform_sub} <- create_platform_subscription(
           %{
             user: user,

             stripe_subscription_id: sub.id,
             stripe_product_id: product_id,
             stripe_price_id: price_id,
             stripe_current_period_end: sub.current_period_end,

             is_active: true,
             started_at: NaiveDateTime.utc_now(),
             ended_at: NaiveDateTime.utc_now(),
           }
         )
    do
      {:ok, platform_sub}
    else
      {:error, %Stripe.Error{user_message: user_message}} -> {:error, user_message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def cancel_subscription(:platform, user) do
    platform_subscription = get_platform_subscription(user)

    with {:ok, sub} <- Stripe.Subscription.delete(platform_subscription.stripe_subscription_id),
         {:ok, platform_sub} <- update_platform_subscription(platform_subscription, %{is_active: false})
      do
      {:ok, platform_sub}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def get_platform_subscription(user) do
    Repo.get_by!(PlatformSubscription, user_id: user.id, is_active: true) |> Repo.preload(:user)
  end

  def has_platform_subscription?(user) do
    Repo.exists?(from s in PlatformSubscription, where: s.user_id == ^user.id and s.is_active == true)
  end

  def get_oauth_connect_url(user) do
    connect_opts = %{
      state: "2686e7a93156ff5af76a83262ac653",
      stripe_user: %{
        "email" => user.email,
      }
    }

    Stripe.Connect.OAuth.authorize_url(connect_opts)
  end

  def oauth_connect(user, code) do
    with {:ok, resp} <- Stripe.Connect.OAuth.token(code) |> IO.inspect(),
         {:ok, _} <- Glimesh.Accounts.set_stripe_user_id(user, resp.stripe_user_id)
    do
      {:ok, "Successfully updated Stripe oauth user."}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  @doc """
  Returns the list of platform_subscription.

  ## Examples

      iex> list_platform_subscription()
      [%PlatformSubscription{}, ...]

  """
  def list_platform_subscriptions do
    Repo.all(PlatformSubscription)
  end

  @doc """
  Creates a platform_subscription.

  ## Examples

      iex> create_platform_subscription(%{field: value})
      {:ok, %PlatformSubscription{}}

      iex> create_platform_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_platform_subscription(attrs \\ %{}) do
    %PlatformSubscription{}
    |> PlatformSubscription.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a platform_subscription.

  ## Examples

      iex> update_platform_subscription(platform_subscription, %{field: new_value})
      {:ok, %PlatformSubscription{}}

      iex> update_platform_subscription(platform_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_platform_subscription(%PlatformSubscription{} = platform_subscription, attrs) do
    platform_subscription
    |> PlatformSubscription.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a platform_subscription.

  ## Examples

      iex> delete_platform_subscription(platform_subscription)
      {:ok, %PlatformSubscription{}}

      iex> delete_platform_subscription(platform_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_platform_subscription(%PlatformSubscription{} = platform_subscription) do
    Repo.delete(platform_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking platform_subscription changes.

  ## Examples

      iex> change_platform_subscription(platform_subscription)
      %Ecto.Changeset{data: %PlatformSubscription{}}

  """
  def change_platform_subscription(%PlatformSubscription{} = platform_subscription, attrs \\ %{}) do
    PlatformSubscription.changeset(platform_subscription, attrs)
  end
end
