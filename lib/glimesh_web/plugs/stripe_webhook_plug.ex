defmodule GlimeshWeb.StripeWebhookPlug do
  import Plug.Conn

  def init(config), do: config

  def call(%{request_path: "/api/webhook/stripe"} = conn, _) do
    webhook_secret = Application.get_env(:stripity_stripe, :webhook_secret)
    [stripe_signature] = get_req_header(conn, "stripe-signature")

    with {:ok, body, _} <- read_body(conn),
         {:ok, stripe_event} <-
           Stripe.Webhook.construct_event(body, stripe_signature, webhook_secret) do
      assign(conn, :stripe_event, stripe_event)
    else
      {:error, error} when is_binary(error) ->
        conn
        |> send_resp(:bad_request, error)
        |> halt()

      {:error, _} ->
        conn
        |> send_resp(:bad_request, "Unexpected error with request")
        |> halt()
    end
  end

  def call(conn, _), do: conn
end
