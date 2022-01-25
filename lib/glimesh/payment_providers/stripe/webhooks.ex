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

  alias Glimesh.PaymentProviders.StripeProvider.ProcessWebhook

  def handle_webhook(%{type: type, data: data}) do
    Rihanna.enqueue({ProcessWebhook, [type, data]})
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
