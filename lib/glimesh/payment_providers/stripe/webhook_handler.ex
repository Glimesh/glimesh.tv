defmodule Glimesh.PaymentProviders.StripeProvider.StripeHandler do
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{} = event) do
    Glimesh.PaymentProviders.StripeProvider.Webhooks.handle_webhook(event)

    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok
end
