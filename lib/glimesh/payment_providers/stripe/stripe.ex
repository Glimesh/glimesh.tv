defmodule Glimesh.PaymentProviders.StripeProvider do
  @moduledoc """
  Business Logic for Stripe
  """
  require Logger

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.Payments
  alias Glimesh.Payments.Subscription
  alias Glimesh.Payments.SubscriptionInvoice

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
      %Subscription{} = subscription ->
        create_subscription_invoice(subscription, invoice)

      nil ->
        Logger.error("Unable to find a Glimesh Subscription for #{invoice.subscription}")
        {:error, "Unable to find a Glimesh Subscription for #{invoice.subscription}"}
    end
  end

  @doc """
  Update a subscription invoice as paid so we can create a transfer for the Streamer at some point in the future.
  """
  def pay_invoice(%Stripe.Invoice{} = invoice) do
    case Glimesh.Payments.get_subscription_invoice_by_stripe_id(invoice.id) do
      %SubscriptionInvoice{} = sub_invoice ->
        # Create invoice for this subscription

        Payments.update_subscription_invoice(sub_invoice, %{
          stripe_status: invoice.status,
          user_paid: true
        })

      nil ->
        # Invoice doesn't already exist, should we create?
        Logger.warn("Unable to find an existing Glimesh Subscription Invoice for #{invoice.id}")
        create_invoice(invoice)
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
          response
        else
          {:pending_taxes, "Something about taxes"}
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
    with {:ok, account} <- Stripe.Account.retrieve(stripe_user_id),
         {:ok, something} <- check_account_capabilities_and_upgrade(account) do
      {:ok, something}
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

    # This is recalculated just in case our cut changes or the invoice is discounted.
    glimesh_cut_percent = 0.50
    glimesh_cut = trunc(total_amount * glimesh_cut_percent)
    potential_payout_amount = total_amount - glimesh_cut

    # Withholding is calculated from the potential payout amount, not the full amount
    withholding_amount =
      if streamer.tax_withholding_percent,
        do:
          Decimal.to_integer(
            Decimal.mult(potential_payout_amount, streamer.tax_withholding_percent)
          ),
        else: 0

    payout_amount = potential_payout_amount - withholding_amount

    Payments.create_subscription_invoice(%{
      # Relations
      user: user,
      streamer: streamer,
      subscription: subscription,
      # Fields
      stripe_invoice_id: invoice.id,
      stripe_status: invoice.status,
      total_amount: total_amount,
      # our_amount: our_amount,
      withholding_amount: withholding_amount,
      payout_amount: payout_amount
    })
  end

  defp create_subscription_invoice(%Subscription{} = subscription, %Stripe.Invoice{} = invoice) do
    # Platform Subscription
    user = Accounts.get_user!(subscription.user_id)

    Payments.create_subscription_invoice(%{
      # Relations
      user: user,
      streamer: nil,
      subscription: subscription,
      # Fields
      stripe_invoice_id: invoice.id,
      stripe_status: invoice.status,
      total_amount: invoice.total,
      withholding_amount: 0,
      payout_amount: 0
    })
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
end
