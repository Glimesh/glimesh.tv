defmodule GlimeshWeb.WebhookController do
  use GlimeshWeb, :controller

  def stripe(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    case Glimesh.PaymentProviders.StripeProvider.Webhooks.handle_webhook(stripe_event) do
      {:ok, _} ->
        conn
        |> send_resp(:ok, "Accepted.")
        |> halt()

      {:error, message} when is_binary(message) ->
        conn
        |> send_resp(:bad_request, message)
        |> halt()

      _ ->
        conn
        |> send_resp(:bad_request, "Unknown error")
        |> halt()
    end
  end

  def taxidpro(%Plug.Conn{assigns: %{taxidpro_body: taxidpro_body}} = conn, _params) do
    with {:ok, event} <- Jason.decode(taxidpro_body),
         {:ok, _} <- Glimesh.PaymentProviders.TaxIDPro.handle_webhook(event) do
      conn
      |> send_resp(:ok, "")
      |> halt()
    else
      {:error, %Jason.DecodeError{}} ->
        conn
        |> send_resp(:bad_request, "Error decoding JSON")
        |> halt()

      _ ->
        conn
        |> send_resp(:bad_request, "Unknown error")
        |> halt()
    end
  end
end
