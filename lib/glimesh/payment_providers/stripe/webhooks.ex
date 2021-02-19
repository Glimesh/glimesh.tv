defmodule Glimesh.PaymentProviders.StripeProvider.Webhooks do
  @moduledoc """
  Stripe Webhook Handler

  Currently Handled:
  - Invoice Created
  - Invoice Paid
  - Account Updated
  - Subscription Renewal
  - Subscription Unpaid / Canceled
  """
  require Logger

  alias Glimesh.PaymentProviders.StripeProvider
  alias Glimesh.Payments

  def handle_webhook(%{
        type: "invoice.created",
        data: %{object: %Stripe.Invoice{} = invoice}
      }) do
    StripeProvider.create_invoice(invoice)
  end

  def handle_webhook(%{
        type: "invoice.paid",
        data: %{object: %Stripe.Invoice{} = invoice}
      }) do
    StripeProvider.pay_invoice(invoice)
  end

  def handle_webhook(%{
        type: "account.updated",
        data: %{object: %Stripe.Account{} = account}
      }) do
    StripeProvider.check_account_capabilities_and_upgrade(account)
  end

  @doc """

  1. A few days prior to renewal, your site receives an invoice.upcoming event at the webhook
    endpoint. You can listen for this event to add extra invoice items to the upcoming invoice.
  2. Your site receives an invoice.paid event.
  3. Your webhook endpoint finds the customer for whom payment was just made.
  4. Your webhook endpoint updates the customer’s current_period_end timestamp in your database
    to the appropriate date in the future (plus a day or two for leeway).
  """
  def handle_webhook(%{
        type: "invoice.payment_succeeded",
        data: %{object: %Stripe.Invoice{} = invoice}
      }) do
    case invoice.status do
      "paid" ->
        Payments.process_successful_renewal(
          invoice.subscription,
          invoice.period_end
        )

      _ ->
        {:ok, ""}
    end
  end

  def handle_webhook(%{
        type: "customer.subscription.updated",
        data: %{object: %Stripe.Subscription{} = subscription}
      }) do
    # When a subscription changes to canceled or unpaid, your webhook script should ensure the
    # customer is no longer receiving your products or services.
    # We decide to give up on a subcription at this point

    case subscription.status do
      "canceled" ->
        Payments.process_unsuccessful_renewal(subscription.id)

      "unpaid" ->
        Payments.process_unsuccessful_renewal(subscription.id)

      _ ->
        {:ok, ""}
    end
  end

  def handle_webhook(%{type: type} = webhook) do
    #   Fall through webhook handler for stripe events, logging into prod for now so we can figure
    # out the right methods to implement.
    Logger.info("Unimplemented Stripe Webhook: #{type} = " <> inspect(webhook))
    {:error, "Webhook endpoint not found for #{type}"}
  end

  def handle_webhook(_) do
    {:error, "Webhook endpoint not correct type."}
  end

  # def handle_webhook(%{type: "invoice.payment_failed"} = stripe_event) do
  #   # Webhook notifications provide a reliable way to be notified of payment failures on
  #   # subscription invoices. A payment failure can be a temporary problem—the card issuer
  #   # declined this charge but may allow the automatic retry—or indicative of a permanent
  #   # blocker, such as not having a usable payment method. When payments fail, an
  #   # invoice.payment_failed event is sent and the status of the PaymentIntent is requires_payment_method.
  #   {:ok, ""}
  # end

  # def handle_webhook(%{type: "charge.failed"} = webhook) do
  #   {:ok, "Something"}
  # end
end
