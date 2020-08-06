defmodule GlimeshWeb.WebhookController do
  use GlimeshWeb, :controller

  def stripe(conn, _params) do
    [signature] = Plug.Conn.get_req_header(conn, "stripe-signature")

    Glimesh.Payments.Providers.Stripe.incoming_webhook(conn.private[:raw_body], signature)

    conn
  end

end
