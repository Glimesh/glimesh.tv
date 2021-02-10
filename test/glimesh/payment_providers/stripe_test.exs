defmodule Glimesh.PaymentProviders.StripeProviderTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  import Glimesh.PaymentsFixtures

  alias Glimesh.PaymentProviders.StripeProvider
  alias Glimesh.PaymentProviders.StripeProvider.Transfers

  def create_and_pay_invoice(id, sub) do
    {:ok, _} =
      StripeProvider.create_invoice(%Stripe.Invoice{
        id: id,
        subscription: sub,
        status: "some_status",
        total: 500
      })

    {:ok, _} =
      StripeProvider.pay_invoice(%Stripe.Invoice{
        id: id,
        subscription: sub,
        status: "paid",
        total: 500
      })
  end

  describe "Stripe Provider" do
    setup do
      %{
        streamer: streamer_fixture(),
        user: user_fixture()
      }
    end

    test "prepare_payouts/0 prepares the correct payouts", %{streamer: streamer, user: user} do
      {:ok, _} = channel_subscription_fixture(streamer, user, "456")
      {:ok, _} = channel_subscription_fixture(streamer, user, "789")

      {:ok, _} =
        StripeProvider.create_invoice(%Stripe.Invoice{
          id: "1",
          subscription: "456",
          status: "some_status",
          total: 500
        })

      {:ok, _} =
        StripeProvider.create_invoice(%Stripe.Invoice{
          id: "2",
          subscription: "789",
          status: "some_status",
          total: 1000
        })

      # Shouldn't have any transfers yet
      assert Transfers.prepare_payouts() == []

      {:ok, _} =
        StripeProvider.pay_invoice(%Stripe.Invoice{
          id: "1",
          subscription: "456",
          status: "paid",
          total: 500
        })

      transfers = Transfers.prepare_payouts()
      transfer_request = hd(transfers)
      assert length(transfers) == 1
      assert transfer_request.transfer.amount == 250
    end

    test "prepare_payouts/0 can prepare multiple payouts", %{streamer: streamer} do
      {:ok, _} = channel_subscription_fixture(streamer, user_fixture(), "456")
      {:ok, _} = channel_subscription_fixture(streamer, user_fixture(), "789")

      create_and_pay_invoice("1", "456")
      create_and_pay_invoice("2", "789")

      transfers = Transfers.prepare_payouts()
      transfer_request = hd(transfers)
      assert length(transfers) == 1
      assert transfer_request.transfer.amount == 500
    end

    test "commit_payouts/1 sends the correct payouts", %{streamer: streamer, user: user} do
      {:ok, _} = channel_subscription_fixture(streamer, user, "456")
      {:ok, _} = channel_subscription_fixture(streamer, user_fixture(), "789")

      create_and_pay_invoice("1", "456")
      create_and_pay_invoice("2", "789")

      transfers = Transfers.prepare_payouts()
      paid_out_transfers = Transfers.commit_payouts(transfers)

      Enum.map(paid_out_transfers, fn {result, data} ->
        assert result == :ok
        assert data.amount == 500
      end)
    end
  end
end
