defmodule GlimeshWeb.StripeWebhookPlug do
  import Plug.Conn
  require Logger

  def init(config), do: config

  def call(%{request_path: "/api/webhook/stripe"} = conn, _) do
    webhook_secret = Application.get_env(:stripity_stripe, :webhook_secret)

    with _ <- Logger.info("Fetching stripe-signature"),
         [stripe_signature] <- get_req_header(conn, "stripe-signature"),
         _ <- Logger.info("Starting read_body"),
         {:ok, body, _} <- read_body(conn),
         _ <- Logger.info("Ending read_body, starting construct_event"),
         {:ok, stripe_event} <-
           Stripe.Webhook.construct_event(body, stripe_signature, webhook_secret),
         _ <- Logger.info("Ending construct_events") do
      assign(conn, :stripe_event, stripe_event)
    else
      [] ->
        Logger.info("Sending bad request about signature")

        conn
        |> send_resp(:bad_request, "Stripe Signature not set in request header")
        |> halt()

      {:error, error} when is_binary(error) ->
        Logger.info("Sending bad with an error message")

        conn
        |> send_resp(:bad_request, error)
        |> halt()

      {:error, _} ->
        Logger.info("Sending unexpected error with request")

        conn
        |> send_resp(:bad_request, "Unexpected error with request")
        |> halt()
    end
  end

  def call(conn, _), do: conn
end
