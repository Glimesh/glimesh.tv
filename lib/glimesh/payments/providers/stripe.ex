defmodule Glimesh.Payments.Providers.Stripe do
  @moduledoc """
  Stripe Webhook Handler

  Unimplemented methods:

  def handle_webhook(%{type: "invoice.paid"} = stripe_event) do
     IO.inspect(stripe_event)
     {:ok, ""}
   end

  def handle_webhook(%{type: "payment_intent.succeeded"} = stripe_event) do
    {:ok, ""}
  end
  """
  require Logger

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
        data: %{object: %Stripe.PaymentIntent{} = payment_intent}
      }) do
    case payment_intent.status do
      "succeeded" ->
        Glimesh.Payments.process_successful_renewal(
          payment_intent.subscription,
          payment_intent.period_end
        )

      _ ->
        # Not sure what this would be
        nil
    end

    {:ok, ""}
  end

  @doc """
  Webhook notifications provide a reliable way to be notified of payment failures on
  subscription invoices. A payment failure can be a temporary problem—the card issuer
  declined this charge but may allow the automatic retry—or indicative of a permanent
  blocker, such as not having a usable payment method. When payments fail, an
  invoice.payment_failed event is sent and the status of the PaymentIntent is requires_payment_method.
  """
  def handle_webhook(%{type: "invoice.payment_failed"} = stripe_event) do
    {:ok, ""}
  end

  def handle_webhook(%{type: "charge.failed"} = webhook) do
    Logger.info("Incoming Stripe Webhook: " <> inspect(webhook))
    {:ok, "Something"}
  end

  @doc """
  Fall through webhook handler for stripe events, logging into prod for now so we can figure
  out the right methods to implement.
  """
  def handle_webhook(%{type: type} = webhook) do
    Logger.info("Incoming Stripe Webhook: " <> inspect(webhook))
    {:error, "Webhook endpoint not found for #{type}"}
  end

  def handle_webhook(_) do
    {:error, "Webhook endpoint not correct type."}
  end
end
