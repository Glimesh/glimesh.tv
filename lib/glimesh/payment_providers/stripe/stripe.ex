defmodule Glimesh.PaymentProviders.StripeProvider do
  @moduledoc """
  Business Logic for Stripe
  """
  require Logger

  use GlimeshWeb, :verified_routes

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Payments
  alias Glimesh.Payments.Payable
  alias Glimesh.Payments.Subscription

  alias Glimesh.PaymentProviders.StripeProvider.Transfers

  @doc """
  Runs a full Payout for Stripe
  """
  def payout do
    Transfers.prepare_payouts()
    |> Transfers.commit_payouts()
  end

  @doc """
  Create a subscription invoice record for us whenever we get a Stripe Invoice.
  We let Stripe handle most of the metadata and only keep information we need
  to show the user, or information we need for Streamer payouts.
  """
  def create_invoice(%Stripe.Invoice{} = invoice) do
    case Glimesh.Payments.get_subscription_by_stripe_id(invoice.subscription) do
      %Subscription{streamer_id: nil} ->
        {:error_unimplemented, "Not currently saving payables for Glimesh direct Subscriptions"}

      %Subscription{} = subscription ->
        create_subscription_invoice(subscription, invoice)

      nil ->
        if invoice.paid do
          Logger.error("Unable to find a Glimesh Subscription for #{invoice.subscription}")
          {:error, "Unable to find a Glimesh Subscription for #{invoice.subscription}"}
        else
          # We get unpaid invoices when users start to subscribe, but don't finish.
          :ok
        end
    end
  end

  @doc """
  Update a subscription invoice as paid so we can create a transfer for the Streamer at some point in the future.
  """
  def pay_invoice(%Stripe.Invoice{} = invoice) do
    case Glimesh.Payments.get_payable_by_source("stripe", invoice.id) do
      %Payable{} = payable ->
        # Create invoice for this subscription

        Payments.update_payable(payable, %{
          status: "paid",
          user_paid_at: NaiveDateTime.utc_now()
        })

      nil ->
        # Invoice doesn't already exist
        case create_invoice(invoice) do
          {:ok, _} ->
            pay_invoice(invoice)

          {:error_unimplemented, msg} ->
            {:error_unimplemented, msg}

          {:error, msg} ->
            {:error, msg}
        end
    end
  end

  def complete_session(%Stripe.Session{} = session) do
    # Completes a session and stores the payment in our DB for proper routing
    donation_id = Payments.get_channel_donation_product_id()
    channel_sub_id = Payments.get_channel_sub_base_product_id()

    case session.metadata do
      %{"type" => "donation", "product_id" => ^donation_id} = payment_router ->
        complete_donation(session, payment_router)

      %{"type" => "gift_subscription", "product_id" => ^channel_sub_id} = payment_router ->
        complete_gift_subscription(session, payment_router)

      _ ->
        {:error, "No matching metadata found"}
    end
  end

  def complete_donation(%Stripe.Session{} = session, payment_router) do
    %{
      "type" => "donation",
      "user_id" => user_id,
      "streamer_id" => streamer_id,
      "amount" => amount_in_cents
    } = payment_router

    amount_in_cents = String.to_integer(amount_in_cents)

    # Get the Stripe fees directly from the payment intent
    total_fees =
      case get_stripe_fees(session.payment_intent) do
        {:ok, total_fees} ->
          total_fees

        _error ->
          # Edge case, sometimes we don't have a payment intent immediately? Guess fees...
          Logger.info("Invalid Payment Intent: #{inspect(session)}")
          ceil(amount_in_cents - (amount_in_cents - amount_in_cents * 0.029 - 30))
      end

    amount_to_be_paid = amount_in_cents - total_fees

    user = Accounts.get_user!(user_id)
    streamer = Accounts.get_user!(streamer_id)

    update_attributes = %{
      status: "paid",

      # These fields are calculated by us
      # Cents of course...
      total_amount: amount_in_cents,
      external_fees: total_fees,
      our_fees: 0,
      withholding_amount: 0,
      payout_amount: amount_to_be_paid
    }

    res =
      case Payments.get_payable_by_source("stripe", session.id) do
        %Payable{} = payable ->
          Payments.update_payable(payable, update_attributes)

        _ ->
          Payments.create_payable(
            Map.merge(update_attributes, %{
              type: "donation",
              external_source: "stripe",
              external_reference: session.id,
              status: "paid",

              # Relations
              user: user,
              streamer: streamer,

              # These fields are what actually happened
              user_paid_at: NaiveDateTime.utc_now()
            })
          )

          # Only notify channel on create
          channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)

          if !is_nil(channel) and Chat.can_create_chat_message?(channel, user) do
            human_amount = :erlang.float_to_binary(amount_in_cents / 100, decimals: 2)

            Chat.create_chat_message(user, channel, %{
              message: " just donated $#{human_amount}!",
              is_subscription_message: true
            })
          end
      end

    case res do
      {:ok, _struct} = resp ->
        resp

      {:error, changeset} ->
        Logger.error("Error saving changeset #{inspect(changeset)}")
        {:error, "Failed to save database record"}
    end
  end

  @doc """
  Complete a gift subscription by creating a payment for the user_doing_gifting and a expiring subscription for user_to_be_gifted.
  """
  def complete_gift_subscription(%Stripe.Session{} = session, payment_router) do
    %{
      "type" => "gift_subscription",
      "product_id" => product_id,
      "price_id" => price_id,
      "user_doing_gifting_id" => user_doing_gifting_id,
      "streamer_id" => streamer_id,
      "user_to_be_gifted_id" => user_to_be_gifted_id,
      "amount" => amount_in_cents
    } = payment_router

    total_amount = String.to_integer(amount_in_cents)

    # Get the Stripe fees directly from the payment intent
    total_fees =
      case get_stripe_fees(session.payment_intent) do
        {:ok, total_fees} ->
          total_fees

        _error ->
          # Edge case, sometimes we don't have a payment intent immediately? Guess fees...
          Logger.info("Invalid Payment Intent: #{inspect(session)}")
          ceil(total_amount - (total_amount - total_amount * 0.029 - 30))
      end

    user_doing_gifting = Accounts.get_user!(user_doing_gifting_id)
    user_to_be_gifted = Accounts.get_user!(user_to_be_gifted_id)
    streamer = Accounts.get_user!(streamer_id)

    # This is recalculated just in case our cut changes or the invoice is discounted.
    glimesh_cut_percent = 0.40
    glimesh_cut = trunc(total_amount * glimesh_cut_percent)
    potential_payout_amount = total_amount - glimesh_cut

    # Withholding is calculated from the potential payout amount, not the full amount
    # Rounded UP in the event the withholding is a fractional percent eg 2.50 - 0.125 = 2.38
    withholding_amount =
      if streamer.tax_withholding_percent,
        do:
          Decimal.to_integer(
            Decimal.round(Decimal.mult(potential_payout_amount, streamer.tax_withholding_percent))
          ),
        else: 0

    payout_amount = potential_payout_amount - withholding_amount

    update_attributes = %{
      status: "paid",

      # These fields are calculated by us
      # Cents of course...
      total_amount: total_amount,
      external_fees: total_fees,
      our_fees: glimesh_cut,
      withholding_amount: withholding_amount,
      payout_amount: payout_amount
    }

    # For laziness, we'll expire the subscription in exactly 30 days
    expires_at = DateTime.utc_now() |> DateTime.add(86_400 * 30)

    with nil <- Payments.get_payable_by_source("stripe", session.id),
         {:ok, _payment} <-
           Payments.create_payable(
             Map.merge(update_attributes, %{
               type: "gift_subscription",
               external_source: "stripe",
               external_reference: session.id,
               status: "paid",

               # Relations
               user: user_doing_gifting,
               streamer: streamer,

               # These fields are what actually happened
               user_paid_at: NaiveDateTime.utc_now()
             })
           ),
         {:ok, product} <- Stripe.Product.retrieve(product_id),
         {:ok, price} <- Stripe.Price.retrieve(price_id),
         {:ok, subscription} <-
           Payments.create_subscription(%{
             from_user: user_doing_gifting,
             user: user_to_be_gifted,
             streamer: streamer,
             stripe_product_id: product_id,
             stripe_price_id: price_id,
             price: price.unit_amount,
             fee: 0,
             payout: price.unit_amount,
             product_name: product.name,
             stripe_subscription_id: nil,
             stripe_current_period_end: DateTime.to_unix(expires_at),
             is_active: true,
             is_canceling: true,
             started_at: NaiveDateTime.utc_now(),
             ended_at: DateTime.to_naive(expires_at)
           }) do
      # Only notify channel on create
      channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)

      if !is_nil(channel) and
           Chat.can_create_chat_message?(channel, user_doing_gifting) do
        Chat.create_chat_message(user_doing_gifting, channel, %{
          message: " just gifted a subscription to #{user_to_be_gifted.displayname}!",
          is_subscription_message: true
        })
      end

      {:ok, subscription}
    else
      %Payable{} = payable ->
        # We just need to update what we have
        Payments.update_payable(payable, update_attributes)

      error ->
        error
    end
    |> case do
      {:ok, _struct} = resp ->
        resp

      {:error, changeset} ->
        Logger.error("Error saving changeset #{inspect(changeset)}")
        {:error, "Failed to save database record"}
    end
  end

  @doc """
  List the countries supported by Stripe's Cross-Border Payouts
  """
  def list_payout_countries do
    Keyword.get(Application.get_env(:glimesh, :stripe_config), :payout_countries, [])
  end

  @doc """
  Start's a Stripe Connect Express handshake by pre-creating the user's Stripe account and also supports continuing an existing but abandoned connect.
  """
  def start_connect(%User{stripe_user_id: nil} = user, country, return_url, refresh_url) do
    # Brand new account
    with {:ok, account} <- Stripe.Account.create(create_account_params(user, country)),
         {:ok, _acct} <- Accounts.set_stripe_user_id(user, account.id),
         {:ok, link} <- get_connect_link(account, return_url, refresh_url) do
      {:ok, link.url}
    end
  end

  def start_connect(%User{stripe_user_id: stripe_user_id}, country, return_url, refresh_url)
      when not is_nil(stripe_user_id) do
    # Existing account
    # Required check to make sure current country and input country match
    with {:ok, account} <- Stripe.Account.retrieve(stripe_user_id),
         true <- account.country == country,
         {:ok, link} <- get_connect_link(account, return_url, refresh_url) do
      {:ok, link.url}
    else
      false ->
        {:error,
         "You are not allowed to setup Glimesh payouts for this country. Please contact support@glimesh.tv"}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Check account from Stripe and see if we can enable the streamer's payouts or not.
  Current Requirements:
    * TOS Accepted
    * Transfers Enabled

  Todo:
    * Prompt the user to go provide Stripe more documents if required.
  """
  def check_account_capabilities_and_upgrade(%Stripe.Account{} = account) do
    transfers_enabled = Map.get(account.capabilities, :transfers, false) == "active"
    tos_accepted = Map.get(account.tos_acceptance, :date, 0) > 0

    cond do
      tos_accepted and transfers_enabled ->
        user = Accounts.get_user_by_stripe_user_id(account.id)

        # We have to manually process taxe formsfor anyone outside the US
        is_tax_verified = account.country == "US"

        response =
          Accounts.set_stripe_attrs(user, %{
            is_stripe_setup: true,
            is_tax_verified: is_tax_verified
          })

        if is_tax_verified do
          channel_url = url(~p"/#{user.username}")

          Glimesh.Accounts.UserNotifier.deliver_sub_button_enabled(
            user,
            channel_url
          )

          response
        else
          {:pending_taxes,
           "Your Stripe account is successfully setup, but you must provide more information regarding your income taxes."}
        end

      tos_accepted and !transfers_enabled ->
        {:pending_stripe,
         "Verifying that your account can receive transfers. Please check back later."}

      transfers_enabled and !tos_accepted ->
        {:pending_stripe, "Verifying your Terms of Service acceptance. Please check back later."}

      true ->
        {:pending_stripe, "Verifying your account details. Please check back later."}
    end
  end

  def check_account_capabilities_and_upgrade(%User{stripe_user_id: stripe_user_id}) do
    case Stripe.Account.retrieve(stripe_user_id) do
      {:ok, account} ->
        check_account_capabilities_and_upgrade(account)
    end
  end

  defp create_subscription_invoice(%Subscription{} = subscription, %Stripe.Invoice{} = invoice)
       when not is_nil(subscription.streamer_id) do
    # Channel Subscription
    # Create invoice for this subscription
    user = Accounts.get_user!(subscription.user_id)
    streamer = Accounts.get_user!(subscription.streamer_id)

    # Figure out if we need to account for a withholding
    # Hold back a widtholding amount
    total_amount = invoice.total

    stripe_fees =
      case get_stripe_fees(invoice.payment_intent) do
        {:ok, fees} ->
          fees

        _ ->
          0
      end

    # This is recalculated just in case our cut changes or the invoice is discounted.
    glimesh_cut_percent = 0.40
    glimesh_cut = trunc(total_amount * glimesh_cut_percent)
    potential_payout_amount = total_amount - glimesh_cut

    # Withholding is calculated from the potential payout amount, not the full amount
    # Rounded UP in the event the withholding is a fractional percent eg 2.50 - 0.125 = 2.38
    withholding_amount =
      if streamer.tax_withholding_percent,
        do:
          Decimal.to_integer(
            Decimal.round(Decimal.mult(potential_payout_amount, streamer.tax_withholding_percent))
          ),
        else: 0

    payout_amount = potential_payout_amount - withholding_amount

    Payments.create_payable(%{
      type: "subscription",
      external_source: "stripe",
      external_reference: invoice.id,
      status: "created",

      # Relations
      user: user,
      streamer: streamer,

      # These fields are calculated by us
      # Cents of course...
      total_amount: total_amount,
      external_fees: stripe_fees,
      our_fees: glimesh_cut,
      withholding_amount: withholding_amount,
      payout_amount: payout_amount
    })
  end

  defp create_subscription_invoice(%Subscription{} = _subscription, %Stripe.Invoice{} = _invoice) do
    # Platform Subscription
    # user = Accounts.get_user!(subscription.user_id)

    # Payments.create_subscription_invoice(%{
    #   # Relations
    #   user: user,
    #   streamer: nil,
    #   subscription: subscription,
    #   # Fields
    #   stripe_invoice_id: invoice.id,
    #   stripe_payment_intent_id: invoice.payment_intent,
    #   stripe_status: invoice.status,
    #   total_amount: invoice.total,
    #   withholding_amount: 0,
    #   payout_amount: 0
    # })

    {:ok, false}
  end

  defp get_connect_link(%Stripe.Account{} = account, return_url, refresh_url) do
    Stripe.AccountLink.create(%{
      account: account.id,
      refresh_url: refresh_url,
      return_url: return_url,
      type: "account_onboarding"
    })
  end

  defp create_account_params(user, "US") do
    %{
      type: "express",
      country: "US",
      email: user.email,
      capabilities: %{
        transfers: %{
          requested: true
        }
      }
    }
  end

  defp create_account_params(user, country) do
    # I don't think these are necessary since Transfers are not connected to Payouts
    # I think the flow will be: Glimesh Transfer's funds to Account weekly, Stripe
    # Payouts happen daily but would not happen on any day except the one after
    # the Glimesh Transfer
    # settings: %{
    #   payouts: %{
    #     schedule: %{
    #       interval: "weekly"
    #     }
    #   }
    # }

    %{
      type: "express",
      country: country,
      email: user.email,
      capabilities: %{
        transfers: %{
          requested: true
        }
      },
      tos_acceptance: %{
        service_agreement: "recipient"
      }
    }
  end

  defp get_stripe_fees(payment_intent) when is_binary(payment_intent) do
    case Stripe.PaymentIntent.retrieve(payment_intent, %{},
           expand: ["charges.data.balance_transaction"]
         ) do
      {:ok, %Stripe.PaymentIntent{charges: %Stripe.List{data: charges}}} ->
        {:ok, Enum.map(charges, fn x -> x.balance_transaction.fee end) |> Enum.sum()}

      error ->
        error
    end
  end

  defp get_stripe_fees(_) do
    {:error, "Invalid payment intent input"}
  end
end
