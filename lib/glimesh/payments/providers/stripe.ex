defmodule Glimesh.Payments.Providers.Stripe do

  def incoming_webhook(raw_http_body, signature) do
    wh_secret = Application.get_env(:stripity_stripe, :webhook_secret)

    {:ok, event} = Stripe.Webhook.construct_event(raw_http_body, signature, wh_secret)

    handle_webhook(event)
  end

  def handle_webhook(%{type: "payment_intent.succeeded"} = stripe_event) do
    IO.inspect(stripe_event)
  end
  def handle_webhook(%{type: type} = stripe_event) do
    {:error, "Webhook endpoint not found for #{type}"}
  end
  def handle_webhook(unknown_event) do
    {:error, "Webhook endpoint not found."}
  end

end
