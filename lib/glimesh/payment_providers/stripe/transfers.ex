defmodule Glimesh.PaymentProviders.StripeProvider.Transfers do
  @moduledoc """
  Stripe Transfers Logic

  This module is responsible for packaging all of the viewer-paid, but streamer-unpaidout invoices, and transfering them to the Streamer's connected account.
  """

  require Logger

  defmodule TransferRequest do
    @moduledoc """
    Structure for holding a Transfer Request
    """

    @enforce_keys [:streamer_id, :invoices, :transfer]
    defstruct [:streamer_id, :invoices, :transfer]
  end

  @doc """
  Prepares a Payout for Stripe, but does not actually run anything
  """
  def prepare_payouts do
    Glimesh.Payments.list_unpaidout_invoices()
    |> invoices_to_transfers()
  end

  @doc """
  Runs a Payout prepared from prepare_payouts/1
  """
  def commit_payouts(transfer_requests) do
    transfer_requests
    |> send_transfers()
  end

  defp invoices_to_transfers(invoices) do
    invoices
    |> Enum.group_by(& &1.streamer_id)
    |> Enum.map(fn {streamer_id, invoices_for_streamer} ->
      streamer = Glimesh.Accounts.get_user!(streamer_id)

      invoices_total = Enum.map(invoices_for_streamer, & &1.total_amount) |> Enum.sum()
      payout_amount = invoices_total / 2

      if payout_amount <= 0 do
        raise "Payout Amount is less than 0 cents, aborting!"
      end

      %TransferRequest{
        streamer_id: streamer_id,
        invoices: invoices_for_streamer,
        transfer: %{
          description: "Glimesh Payout #x",
          destination: streamer.stripe_user_id,
          # trunc should be safe because we only ever work in USD cents so we're just converting a float to int
          amount: trunc(payout_amount),
          currency: "USD",
          metadata: %{
            included_invoices:
              Enum.map(invoices_for_streamer, & &1.stripe_invoice_id) |> Enum.join(", ")
          }
        }
      }
    end)
  end

  defp send_transfers(transfers) do
    Enum.map(transfers, fn transfer_request ->
      %{streamer_id: streamer_id, invoices: invoices, transfer: transfer_input} = transfer_request

      case Stripe.Transfer.create(transfer_input) do
        {:ok, %Stripe.Transfer{} = transfer} ->
          update_invoices_as_paid(transfer, invoices)

          {:ok, transfer}

        some_error ->
          Logger.error("Error processing Stripe Transfer for user_id=#{streamer_id}")
          {:error, some_error}
      end
    end)
  end

  defp update_invoices_as_paid(%Stripe.Transfer{} = transfer, invoices) do
    Enum.map(invoices, fn invoice ->
      case Glimesh.Payments.update_subscription_invoice(invoice, %{
             streamer_paidout: true,
             streamer_payout_amount: transfer.amount,
             stripe_transfer_id: transfer.id
           }) do
        {:ok, invoice} ->
          {:ok, invoice}

        some_error ->
          Logger.emergency("Unexpected error saving Subscription Invoice #{invoice.id}")
          {:error, some_error}
      end
    end)
  end

  @doc """
  After a weekly payout, run through our invoices and check for any un-paid out invoices. Maybe throw an error so we can catch it in AppSignal?
  """
  def check_for_unpaidout_invoices do
    raise "Not implemented"
  end
end
