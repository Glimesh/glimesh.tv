defmodule GlimeshWeb.TaxIDProWebhookPlug do
  @moduledoc """

    You may want to verify that the webhook was sent by taxid.pro. The webhooks include a Webhook-Signature
    header containing an HMAC in hex format. You can recalculate the signature by using the signature secret
    in your webhook settings, and by following these steps:

      1. Convert the request body from a JSON object to a string, if necessary.
      2. Using a library such as crypto, recalculate the signature using the sha-256 algorithm.
      3. Compare the signature from your header to the recalculated signature. Use a constant-time comparison
          algorithm to avoid leaking timing information.

  """

  import Plug.Conn

  def init(config), do: config

  def call(%{request_path: "/api/webhook/taxidpro"} = conn, _) do
    webhook_secret =
      Application.get_env(:glimesh, Glimesh.PaymentProviders.TaxIDPro)[:webhook_secret]

    [webhook_signature] = get_req_header(conn, "webhook-signature")

    with {:ok, body, _} <- read_body(conn),
         {:ok, safe_body} <-
           validate_secret(body, webhook_signature, webhook_secret) do
      assign(conn, :taxidpro_body, safe_body)
    else
      {:error, message} ->
        conn
        |> send_resp(:bad_request, message)
        |> halt()
    end
  end

  def call(conn, _), do: conn

  defp validate_secret(body, webhook_signature, webhook_secret) do
    hmac = :crypto.mac(:hmac, :sha256, webhook_secret, body) |> Base.encode16(case: :lower)

    if hmac == webhook_signature do
      {:ok, body}
    else
      {:error, "Does not compute"}
    end
  end
end
