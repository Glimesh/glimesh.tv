defmodule Glimesh.PaymentProviders.StripeProvider.StripeHandler do
  @moduledoc false
  @behaviour Stripe.WebhookHandler

  alias Glimesh.PaymentProviders.StripeProvider.ProcessWebhook

  @impl true
  def handle_event(%Stripe.Event{} = event) do
    # We don't actually save data, due to Oban encoding. However we'll re-fetch the event based on the ID from stripe
    # inside the queue for processing.
    %{id: event.id, object: event.object, type: event.type}
    |> ProcessWebhook.new()
    |> Oban.insert()

    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok
end
