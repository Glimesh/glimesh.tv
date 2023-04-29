defmodule Glimesh.PaymentProviders.StripeProvider.Transfers do
  @moduledoc """
  Stripe Transfers Logic

  This module is responsible for packaging all of the viewer-paid, but streamer-unpaidout payables, and transferring them to the Streamer's connected account.

  Includes:
   * Subscriptions
   * Donations
  """

  require Logger

  defmodule TransferRequest do
    @moduledoc """
    Structure for holding a Transfer Request
    """

    @enforce_keys [:streamer_id, :payables, :transfer]
    defstruct [:streamer_id, :payables, :transfer]
  end

  @doc """
  Prepares a Payout for Stripe, but does not actually run anything
  """
  def prepare_payouts do
    Glimesh.Payments.list_unpaidout_payables()
    |> payables_to_transfers()
  end

  @doc """
  Runs a Payout prepared from prepare_payouts/1
  """
  def commit_payouts(transfer_requests) do
    transfer_requests
    |> send_transfers()
  end

  defp payables_to_transfers(payables) do
    payables
    |> Enum.group_by(& &1.streamer_id)
    |> Enum.map(fn {streamer_id, payables_for_streamer} ->
      streamer = Glimesh.Accounts.get_user!(streamer_id)

      payout_amount = Enum.map(payables_for_streamer, & &1.payout_amount) |> Enum.sum()

      if payout_amount <= 0 do
        raise "Payout Amount is less than 0 cents, aborting!"
      end

      payables_string = Enum.map_join(payables_for_streamer, ", ", & &1.external_reference)

      # Figure out better way of storing this info, since Stripe has a 500 char limit
      included_payables =
        if String.length(payables_string) >= 500,
          do:
            Enum.map_join(
              payables_for_streamer,
              ", ",
              &String.slice(&1.external_reference, 0, 15)
            ),
          else: payables_string

      %TransferRequest{
        streamer_id: streamer_id,
        payables: payables_for_streamer,
        transfer: %{
          description: "Glimesh Payout on " <> Date.to_string(NaiveDateTime.utc_now()),
          destination: streamer.stripe_user_id,
          # trunc should be safe because we only ever work in USD cents so we're just converting a float to int
          amount: trunc(payout_amount),
          currency: "USD",
          metadata: %{
            total_withholding_amount:
              Enum.map(payables_for_streamer, & &1.withholding_amount) |> Enum.sum(),
            included_payables: included_payables
          }
        }
      }
    end)
  end

  defp send_transfers(transfers) do
    Enum.map(transfers, fn transfer_request ->
      %{streamer_id: streamer_id, payables: payables, transfer: transfer_input} = transfer_request

      case Stripe.Transfer.create(transfer_input) do
        {:ok, %Stripe.Transfer{} = transfer} ->
          update_payables_as_paid(transfer, payables)
          {:ok, transfer}

        some_error ->
          Logger.error("Error processing Stripe Transfer for user_id=#{streamer_id}")
          {:error, some_error}
      end
    end)
  end

  defp update_payables_as_paid(%Stripe.Transfer{} = transfer, payables) do
    Enum.map(payables, fn payable ->
      case Glimesh.Payments.update_payable(payable, %{
             status: "paidout",
             streamer_payout_at: NaiveDateTime.utc_now(),
             streamer_payout_amount: transfer.amount,
             stripe_transfer_id: transfer.id
           }) do
        {:ok, payable} ->
          {:ok, payable}

        some_error ->
          Logger.error("Unexpected error saving Payable #{payable.id}")
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

  alias Glimesh.PaymentProviders.StripeProvider

  import Ecto.Query

  # credo:disable-for-lines:35
  def audit_unpaid_payables do
    # Check all of our payables against Stripe to ensure they are in the right place
    Glimesh.Repo.all(
      from(pb in Glimesh.Payments.Payable,
        where: is_nil(pb.streamer_payout_at)
      )
    )
    |> Enum.map(fn
      payable ->
        cond do
          String.starts_with?(payable.external_reference, "in_") ->
            # Invoice
            {:ok, invoice} = Stripe.Invoice.retrieve(payable.external_reference)

            case [invoice.status, payable.status] do
              ["paid", "created"] ->
                # IO.puts(
                #   "#{payable.external_reference} has #{invoice.status} in Stripe, #{payable.status} locally."
                # )
                # ignore for now
                {:ok, _} = StripeProvider.pay_invoice(invoice)

              _ ->
                # Anything else is fine
                nil
            end

          String.starts_with?(payable.external_reference, "cs_live_") ->
            {:ok, session} = Stripe.Session.retrieve(payable.external_reference)
            # Donation, should be infrequent
            IO.puts(
              "#{payable.external_reference} is a donation with status #{session.payment_status}, #{payable.status} locally."
            )
        end
    end)
  end
end
