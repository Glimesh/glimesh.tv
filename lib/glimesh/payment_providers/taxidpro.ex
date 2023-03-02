defmodule Glimesh.PaymentProviders.TaxIDPro do
  @moduledoc """
  API Wrapper for Tax ID Pro
  """

  require Logger

  use GlimeshWeb, :verified_routes

  alias Glimesh.Accounts.User

  @doc """
  Request a new W-8BEN form link from Tax ID Pro

  From what I can tell it's okay to make many of these requests

  """
  def request_w8ben(%User{} = user, return_url) do
    {:ok, request_body} =
      %{
        key: Application.get_env(:glimesh, Glimesh.PaymentProviders.TaxIDPro)[:api_key],
        formNumber: "w8ben",
        thankYouUrl: return_url,
        autofill: %{
          line10Income: %{
            value: "copyright12",
            disabled: true
          }
        },
        metadata: %{
          userId: user.id
        }
      }
      |> Jason.encode()

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post("https://api.taxid.pro/formRequests", request_body, [
             {"Content-Type", "application/json"}
           ]),
         {:ok, response} <- Jason.decode(body),
         %{"url" => url} <- response do
      {:ok, url}
    else
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Unexpected response from API."}

      _ ->
        {:error, "Unexpected response from API."}
    end
  end

  @doc """
  Handle a webhook for a completed W-8BEN form

    The webhook will be attempted until it receives a 200 OK response from your server.
    It will be attempted a maximum of three times in 10-minute increments.

  {
    "type": "form.w9.created",
    "form": {
      "senderEmail": "user@email.com",
      "token": "Joi87iuhIUhzu968u876ini9",
      "name": "John Doe",
      "businessName": "Business, Inc.",
      "formNumber": "w9",
      "formNumberPretty": "W-9",
      "metadata": { ... },
      "w9": { ... },
    }
  }
  """
  def handle_webhook(%{"type" => "form.w8ben.created", "form" => form}) do
    user = Glimesh.Accounts.get_user!(form["metadata"]["userId"])

    case Glimesh.Accounts.set_stripe_attrs(user, %{
           is_tax_verified: true,
           tax_withholding_percent: determine_tax_percent(form)
         }) do
      {:ok, user} ->
        channel_url = url(~p"/#{user.username}")

        Glimesh.Accounts.UserNotifier.deliver_sub_button_enabled(
          user,
          channel_url
        )

        {:ok, user}

      {:error, _} ->
        {:error, "Problem updating user."}
    end
  end

  def handle_webhook(_) do
    {:error, "Unhandled form"}
  end

  defp determine_tax_percent(%{"w8ben" => w8}) do
    selected_rate = Map.get(w8, "line10Rate", nil)
    # temporary production debugging, non-sensetive info
    Logger.info("Selected Rate: #{inspect(selected_rate)}")

    cond do
      Map.get(w8, "line6ForeignTin", "") == "" ->
        # If Foreign Tax ID is not provided, we must default to 30% withholding
        0.30

      is_nil(selected_rate) or selected_rate == "" ->
        # If selected rate is unexpected, default to 30%
        0.30

      selected_rate > 0.30 ->
        # Rate is somehow more than 30%
        0.30

      selected_rate < 0.00 ->
        # Rate is somehow less than 0
        0.00

      is_float(selected_rate) ->
        # If we have a real rate
        selected_rate

      selected_rate == 0 ->
        0.00

      true ->
        # Default if all else fails
        0.30
    end
  end
end
