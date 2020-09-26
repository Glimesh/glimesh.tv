defmodule GlimeshWeb.WebhookController do
  use GlimeshWeb, :controller

  def stripe(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    Glimesh.Payments.Providers.Stripe.handle_webhook(stripe_event)

    send_resp(conn, :ok, "")
  end
end
