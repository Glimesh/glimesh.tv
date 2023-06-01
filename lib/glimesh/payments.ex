defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.Accounts.UserPreference
  alias Glimesh.Payments.Payable
  alias Glimesh.Payments.Subscription
  alias Glimesh.Payments.SubscriptionInvoice
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

  def get_channel_donation_product_id, do: get_stripe_config(:channel_donation_product_id)

  def get_stripe_config(key) do
    Application.get_env(:glimesh, :stripe_config)[key]
  end

  def list_all_subscriptions do
    Repo.replica().all(
      from s in Subscription,
        where: s.is_active == true
    )
    |> Repo.preload([:user, :streamer])
  end

  def list_streamer_subscribers(streamer) do
    Repo.replica().all(
      from s in Subscription,
        where: s.streamer_id == ^streamer.id and s.is_active == true
    )
    |> Repo.preload([:user, :streamer])
  end

  def list_user_subscriptions(user) do
    Repo.replica().all(
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
    if is_platform_subscriber?(user) do
      raise ArgumentError, "You already have an active subscription to Glimesh."
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
    case get_channel_subscription(user, streamer) do
      %Subscription{} = sub ->
        if is_nil(sub.stripe_subscription_id) and not is_nil(sub.from_user_id) do
          convert_gift_to_subscription(user, streamer, price_id)
        else
          # Is this right?
          new_subscription_to_channel(user, streamer, product_id, price_id)
        end

      _ ->
        new_subscription_to_channel(user, streamer, product_id, price_id)
    end
  end

  def new_subscription_to_channel(user, streamer, product_id, price_id) do
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
      items: [%{price: price_id}]
    }

    glimesh_cut_percent = 10

    sub_attrs = %{
      user: user,
      streamer: streamer,
      stripe_product_id: product_id,
      stripe_price_id: price_id,
      price: price.unit_amount,
      fee: trunc(glimesh_cut_percent / 100 * price.unit_amount),
      payout: trunc(price.unit_amount - glimesh_cut_percent / 100 * price.unit_amount),
      product_name: product.name
    }

    results =
      Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"])
      |> handle_stripe_subscription_create(user, sub_attrs)

    case results do
      {:ok, %Subscription{}} ->
        channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)

        if !is_nil(channel) and Glimesh.Chat.can_create_chat_message?(channel, user) do
          Glimesh.Chat.create_chat_message(user, channel, %{
            message: " just subscribed!",
            is_subscription_message: true
          })
        end

        results

      _ ->
        results
    end
  end

  def convert_gift_to_subscription(user, streamer, price_id) do
    if user.id == streamer.id do
      raise ArgumentError, "You cannot subscribe to yourself."
    end

    existing_sub = get_channel_subscription!(user, streamer)

    if not existing_sub.is_canceling or not is_nil(existing_sub.stripe_subscription_id) do
      raise ArgumentError, "You cannot upgrade a non-gifted sub."
    end

    customer_id = Accounts.get_stripe_customer_id(user)

    stripe_input = %{
      customer: customer_id,
      trial_end: existing_sub.stripe_current_period_end,
      items: [%{price: price_id}]
    }

    with {:ok, %Stripe.Subscription{} = stripe_sub} <-
           Stripe.Subscription.create(stripe_input, expand: ["latest_invoice.payment_intent"]),
         {:ok, subscription} <-
           update_subscription(existing_sub, %{
             stripe_subscription_id: stripe_sub.id,
             is_canceling: false,
             ended_at:
               stripe_sub.current_period_end |> DateTime.from_unix!() |> DateTime.to_naive()
           }) do
      {:ok, subscription}
    else
      error ->
        error
    end
  end

  @doc """
  Start a channel donation by creating a Stripe Checkout Session, and returning a URL that the user can finish the payment on. This method is bundled with a webhook from Stripe to finalize the donation.

  Currently no state is saved unless the webhook comes back through the API.
  If a checkout session is abandoned, Stripe will automatically delete it in a day.
  """
  def start_channel_donation(%User{} = user, %User{} = streamer, amount_in_cents, return_url)
      when is_integer(amount_in_cents) do
    cond do
      user.id == streamer.id ->
        {:validation, "You cannot donate to yourself."}

      amount_in_cents < 100 or amount_in_cents > 10_000 ->
        {:validation, "Amount must be more than 1.00 and less than 100.00."}

      true ->
        description = "Donation to #{streamer.displayname}"

        stripe_input = %{
          "cancel_url" => return_url,
          "success_url" => return_url <> "?stripe_session_id={CHECKOUT_SESSION_ID}",
          "mode" => "payment",
          "payment_method_types" => [
            "card"
          ],
          "submit_type" => "donate",
          "customer" => Accounts.get_stripe_customer_id(user),
          "payment_intent_data" => %{
            "description" => description
          },
          "line_items" => [
            %{
              "description" => description,
              "quantity" => 1,
              "price_data" => %{
                "product" => get_channel_donation_product_id(),
                "currency" => "USD",
                "unit_amount" => amount_in_cents
              }
            }
          ],
          "metadata" => %{
            "type" => "donation",
            "product_id" => get_channel_donation_product_id(),
            "user_id" => user.id,
            "streamer_id" => streamer.id,
            "amount" => amount_in_cents
          }
        }

        Stripe.Session.create(stripe_input)
    end
  end

  @doc """
  Start a gift subscription from a user, to a user, for a streamer.
  This method is bundled with a webhook from Stripe to finalize the donation.

  Currently no state is saved unless the webhook comes back through the API.
  If a checkout session is abandoned, Stripe will automatically delete it in a day.

  Additional metadata is used to store who the subscription is for, but it needs to show
  up in user_doing_gifting's payment history.
  """
  def start_gift_subscription(
        %User{} = user_doing_gifting,
        %User{} = streamer,
        %User{} = user_to_be_gifted,
        amount_in_cents,
        return_url
      )
      when is_integer(amount_in_cents) do
    possible_channel_sub = get_channel_subscription(user_to_be_gifted, streamer)
    preferences = get_user_preferences(user_to_be_gifted)

    cond do
      not is_nil(possible_channel_sub) ->
        {:validation, "The recipient already has a subscription for this channel."}

      user_doing_gifting.id == user_to_be_gifted.id ->
        {:validation, "You cannot gift a subscription to yourself."}

      user_to_be_gifted.id == streamer.id ->
        {:validation, "You cannot gift a subscription to the streamer."}

      amount_in_cents < 100 or amount_in_cents > 10_000 ->
        {:validation, "Amount must be more than 1.00 and less than 100.00."}

      not preferences.gift_subs_enabled ->
        {:validation, "This user has opted out of receiving gift subscriptions"}

      true ->
        description =
          "Gift subscription to #{user_to_be_gifted.displayname} for #{streamer.displayname}"

        stripe_input = %{
          "cancel_url" => return_url,
          "success_url" => return_url <> "?stripe_session_id={CHECKOUT_SESSION_ID}",
          "mode" => "payment",
          "payment_method_types" => [
            "card"
          ],
          "submit_type" => "pay",
          "customer" => Accounts.get_stripe_customer_id(user_doing_gifting),
          "payment_intent_data" => %{
            "description" => description
          },
          "line_items" => [
            %{
              "description" => description,
              "quantity" => 1,
              "price_data" => %{
                "product" => get_channel_sub_base_product_id(),
                "currency" => "USD",
                "unit_amount" => amount_in_cents
              }
            }
          ],
          "metadata" => %{
            "type" => "gift_subscription",
            "product_id" => get_channel_sub_base_product_id(),
            "price_id" => get_channel_sub_base_price_id(),
            "user_doing_gifting_id" => user_doing_gifting.id,
            "streamer_id" => streamer.id,
            "user_to_be_gifted_id" => user_to_be_gifted.id,
            "amount" => amount_in_cents
          }
        }

        Stripe.Session.create(stripe_input)
    end
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

  @doc """
  Resubscribe to the subscription.
  Only allowed if the stripe subscription is not cancelled
  """
  def resubscribe(%Subscription{is_active: true} = subscription) do
    with {:ok, stripe_sub} <-
           Stripe.Subscription.update(subscription.stripe_subscription_id, %{
             cancel_at_period_end: false
           }),
         {:ok, sub} <-
           update_subscription(subscription, %{
             is_canceling: false,
             ended_at:
               stripe_sub.current_period_end |> DateTime.from_unix!() |> DateTime.to_naive()
           }) do
      {:ok, sub}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  def resubscribe(%Subscription{is_active: false}) do
    {:error, "Cannot resubscribe an expired subscription."}
  end

  def unsubscribe(subscription) do
    with {:ok, stripe_sub} <-
           Stripe.Subscription.update(subscription.stripe_subscription_id, %{
             cancel_at_period_end: true
           }),
         {:ok, sub} <-
           update_subscription(subscription, %{
             is_canceling: true,
             ended_at:
               stripe_sub.current_period_end |> DateTime.from_unix!() |> DateTime.to_naive()
           }) do
      {:ok, sub}
    else
      {:error, %Stripe.Error{} = error} -> {:error, error.user_message || error.message}
      {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors}
    end
  end

  @doc """
  Immediately cancel a subscription -- do not use unless working with Stripe webhooks
  """
  def cancel(subscription) do
    case update_subscription(subscription, %{is_canceling: false, is_active: false}) do
      {:ok, sub} ->
        {:ok, sub}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.user_message || error.message}

      {:error, %Ecto.Changeset{errors: errors}} ->
        {:error, errors}
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
        cancel(sub)

      _ ->
        {:error, "Unable to find subscription by stripe_subscription_id"}
    end
  end

  @doc """
  Does the user have payout history we should not be deleting from Stripe?
  """
  def has_payout_history?(%User{} = user) do
    Repo.exists?(from s in Subscription, where: s.streamer_id == ^user.id)
  end

  @doc """
  Delete a Stripe Connect Account

  Will error if the account still has a balance
  """
  def delete_stripe_account(%User{stripe_user_id: stripe_user_id} = user)
      when not is_nil(stripe_user_id) do
    if has_payout_history?(user) == false do
      case Stripe.Account.delete(stripe_user_id) do
        {:ok, _} ->
          Glimesh.Accounts.set_stripe_attrs(user, %{
            stripe_user_id: nil,
            is_stripe_setup: false
          })

        {:error, %Stripe.Error{} = error} ->
          {:error, error.user_message || error.message}
      end
    else
      {:error, "User has payout history, cannot delete Stripe account."}
    end
  end

  def get_subscription_by_stripe_id(subscription_id) when is_binary(subscription_id) do
    Repo.one(
      from s in Subscription,
        where: s.stripe_subscription_id == ^subscription_id
    )
  end

  def get_subscription_by_stripe_id(nil), do: nil

  def get_platform_subscription(user) do
    Repo.one(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and is_nil(s.streamer_id)
    )
    |> Repo.preload(:user)
  end

  def is_platform_subscriber?(user) do
    Repo.exists?(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and is_nil(s.streamer_id)
    )

    true
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

    true
  end

  def get_channel_subscriptions(user) do
    Repo.replica().all(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and not is_nil(s.streamer_id)
    )
    |> Repo.preload([:user, :streamer, :from_user])
  end

  def get_channel_subscription(user, streamer) do
    Repo.replica().get_by(Subscription,
      user_id: user.id,
      is_active: true,
      streamer_id: streamer.id
    )
    |> Repo.preload([:user, :streamer])
  end

  def get_channel_subscription!(user, streamer) do
    Repo.replica().get_by!(Subscription,
      user_id: user.id,
      is_active: true,
      streamer_id: streamer.id
    )
    |> Repo.preload([:user, :streamer])
  end

  def get_user_preferences(user) do
    Repo.replica().get_by(UserPreference,
      user_id: user.id
    )
  end

  def has_channel_subscription?(user, streamer) do
    Repo.exists?(
      from s in Subscription,
        where:
          s.user_id == ^user.id and
            s.is_active == true and
            s.streamer_id == ^streamer.id
    )
  end

  def is_subscribed?(%Channel{} = channel, %User{} = user) do
    Repo.exists?(
      from s in Subscription,
        where: s.user_id == ^user.id and s.is_active == true and s.streamer_id == ^channel.user_id
    )
  end

  def list_platform_founder_subscribers do
    Glimesh.QueryCache.get_and_store!(
      "Glimesh.Payments.list_platform_founder_subscribers()",
      fn ->
        {:ok,
         Repo.replica().all(
           from s in Subscription,
             where:
               s.is_active == true and is_nil(s.streamer_id) and
                 s.stripe_product_id == ^get_platform_sub_founder_product_id()
         )
         |> Repo.preload(:user)}
      end
    )
  end

  def list_platform_supporter_subscribers do
    Glimesh.QueryCache.get_and_store!(
      "Glimesh.Payments.list_platform_supporter_subscribers()",
      fn ->
        {:ok,
         Repo.replica().all(
           from s in Subscription,
             where:
               s.is_active == true and is_nil(s.streamer_id) and
                 s.stripe_product_id == ^get_platform_sub_supporter_product_id()
         )
         |> Repo.preload(:user)}
      end
    )
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

  def count_incoming(user) do
    Repo.one(
      from s in Subscription,
        select: count(s.id),
        where: s.streamer_id == ^user.id and s.is_active == true
    )
  end

  def count_outgoing(user) do
    Repo.one(
      from s in Subscription,
        select: count(s.id),
        where: s.user_id == ^user.id and s.is_active == true
    )
  end

  def list_payment_history(%User{stripe_customer_id: nil}), do: []

  def list_payment_history(%User{stripe_customer_id: stripe_customer_id}) do
    {:ok, payment_history} = Stripe.Charge.list(%{customer: stripe_customer_id})

    payment_history.data
  end

  def list_payables_history(%User{} = user) do
    Repo.replica().all(
      from p in Payable,
        select: struct(p, [:streamer_payout_at, :streamer_payout_amount, :stripe_transfer_id]),
        where: p.streamer_id == ^user.id and not is_nil(p.streamer_payout_at),
        group_by: [p.streamer_payout_at, p.streamer_payout_amount, p.stripe_transfer_id],
        order_by: [desc: p.streamer_payout_at]
    )
  end

  # Not ready for this yet...
  # @doc """
  # List our historical payouts for the user
  # """
  # def list_payout_history(%User{} = streamer) do
  #   Repo.replica().all(
  #     from si in SubscriptionInvoice,
  #       where:
  #         si.streamer_id == ^streamer.id and si.user_paid == true and si.streamer_paidout == true
  #   )
  # end

  @doc """
  Returns the list of subscription.

  ## Examples

      iex> list_subscription()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.replica().all(Subscription)
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

  # Subscription Invoices

  def get_subscription_invoice_by_stripe_id(invoice_id) when is_binary(invoice_id) do
    Repo.one(
      from s in SubscriptionInvoice,
        where: s.stripe_invoice_id == ^invoice_id
    )
  end

  def list_unpaidout_invoices do
    Repo.replica().all(
      from si in SubscriptionInvoice,
        where:
          not is_nil(si.streamer_id) and si.user_paid == true and si.streamer_paidout == false
    )
  end

  def list_unpaidout_payables do
    Repo.replica().all(
      from pb in Payable,
        where:
          not is_nil(pb.streamer_id) and not is_nil(pb.user_paid_at) and
            is_nil(pb.streamer_payout_at)
    )
  end

  @doc """
  Returns the list of subscription invoices.

  ## Examples

      iex> list_subscription_invoices()
      [%SubscriptionInvoice{}, ...]

  """
  def list_subscription_invoices do
    Repo.replica().all(SubscriptionInvoice)
  end

  @doc """
  Creates a subscription invoice.

  ## Examples

      iex> create_subscription_invoice(%{field: value})
      {:ok, %SubscriptionInvoice{}}

      iex> create_subscription_invoice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription_invoice(attrs \\ %{}) do
    %SubscriptionInvoice{}
    |> SubscriptionInvoice.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription invoice.

  ## Examples

      iex> update_subscription_invoice(invoice, %{field: new_value})
      {:ok, %SubscriptionInvoice{}}

      iex> update_subscription_invoice(invoice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription_invoice(%SubscriptionInvoice{} = invoice, attrs) do
    invoice
    |> SubscriptionInvoice.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription invoice.

  ## Examples

      iex> delete_subscription_invoice(invoice)
      {:ok, %SubscriptionInvoice{}}

      iex> delete_subscription_invoice(invoice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription_invoice(%SubscriptionInvoice{} = invoice) do
    Repo.delete(invoice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription invoice changes.

  ## Examples

      iex> change_subscription_invoice(invoice)
      %Ecto.Changeset{data: %SubscriptionInvoice{}}

  """
  def change_subscription_invoice(%SubscriptionInvoice{} = invoice, attrs \\ %{}) do
    SubscriptionInvoice.create_changeset(invoice, attrs)
  end

  def get_payable_by_source(source, reference) when is_binary(source) and is_binary(reference) do
    Repo.one(
      from pb in Payable,
        where: pb.external_source == ^source and pb.external_reference == ^reference
    )
  end

  @doc """
  Creates a payable.

  ## Examples

      iex> create_payable(%{field: value})
      {:ok, %Payable{}}

      iex> create_payable(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payable(attrs \\ %{}) do
    %Payable{}
    |> Payable.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a payable.

  ## Examples

      iex> update_payable(payable, %{field: new_value})
      {:ok, %Payable{}}

      iex> update_payable(payable, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payable(%Payable{} = payable, attrs) do
    payable
    |> Payable.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payable changes.

  ## Examples

      iex> change_payable(payable)
      %Ecto.Changeset{data: %Payable{}}

  """
  def change_payable(%Payable{} = payable, attrs \\ %{}) do
    Payable.create_changeset(payable, attrs)
  end

  @doc """
  Utility function to convert our subscription_invoices over to payables.
  """
  def convert_subscription_invoices_to_payables do
    subscription_invoices =
      Repo.replica().all(
        from si in SubscriptionInvoice,
          where: not is_nil(si.streamer_id)
      )

    Enum.each(subscription_invoices, fn %SubscriptionInvoice{} = invoice ->
      user = Accounts.get_user!(invoice.user_id)
      streamer = Accounts.get_user!(invoice.streamer_id)

      create_payable(%{
        type: "subscription",
        external_source: "stripe",
        external_reference: invoice.stripe_invoice_id,
        status: if(invoice.streamer_paidout, do: "paidout", else: "paid"),
        user: user,
        streamer: streamer,
        total_amount: invoice.total_amount,
        external_fees: 0,
        our_fees: invoice.total_amount - (invoice.payout_amount + invoice.withholding_amount),
        withholding_amount: invoice.withholding_amount,
        payout_amount: invoice.payout_amount,
        user_paid_at: invoice.inserted_at,
        streamer_payout_at: if(invoice.streamer_paidout, do: invoice.updated_at, else: nil),
        streamer_payout_amount: invoice.streamer_payout_amount,
        stripe_transfer_id: invoice.stripe_transfer_id
      })
    end)
  end
end
