defmodule GlimeshWeb.WebhookController do
  use GlimeshWeb, :controller

  require Logger

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
