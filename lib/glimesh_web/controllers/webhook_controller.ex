defmodule GlimeshWeb.WebhookController do
  use GlimeshWeb, :controller

  def stripe(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    Glimesh.PaymentProviders.StripeProvider.Webhooks.handle_webhook(stripe_event)

    send_resp(conn, :ok, "")
  end

  def taxidpro(%Plug.Conn{assigns: %{taxidpro_body: taxidpro_body}} = conn, _params) do
    with {:ok, event} <- Jason.decode(taxidpro_body),
         {:ok, _} <- Glimesh.PaymentProviders.TaxIDPro.handle_webhook(event) do
      send_resp(conn, :ok, "")
    else
      {:error, %Jason.DecodeError{}} ->
        send_resp(conn, :bad_request, "Error decoding JSON")

      _ ->
        send_resp(conn, :bad_request, "Unknown error")
    end
  end
end
