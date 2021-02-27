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

    StripeProvider.pay_invoice(%Stripe.Invoice{
      id: id,
      subscription: sub,
      status: "paid",
      total: 500
    })
  end

  describe "Normal Payouts" do
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

  describe "Witholding Payouts 30%" do
    setup do
      {:ok, streamer} =
        Glimesh.Accounts.set_stripe_attrs(streamer_fixture(), %{
          is_stripe_setup: true,
          is_tax_verified: true,
          tax_withholding_percent: 0.30
        })

      %{
        streamer: streamer,
        user: user_fixture()
      }
    end

    test "prepare_payouts/0 prepares the correct amount with withholding", %{
      streamer: streamer,
      user: user
    } do
      {:ok, _} = channel_subscription_fixture(streamer, user, "456")
      {:ok, _} = channel_subscription_fixture(streamer, user, "789")

      create_and_pay_invoice("1", "456")
      {:ok, subscription_invoice} = create_and_pay_invoice("2", "789")
      assert subscription_invoice.total_amount == 500
      assert subscription_invoice.withholding_amount == 75
      assert subscription_invoice.payout_amount == 175

      transfers = Transfers.prepare_payouts()
      paid_out_transfers = Transfers.commit_payouts(transfers)

      Enum.map(paid_out_transfers, fn {result, data} ->
        assert result == :ok
        assert data.amount == 350
      end)
    end
  end

  describe "Witholding Payouts 5%" do
    setup do
      {:ok, streamer} =
        Glimesh.Accounts.set_stripe_attrs(streamer_fixture(), %{
          is_stripe_setup: true,
          is_tax_verified: true,
          tax_withholding_percent: 0.05
        })

      %{
        streamer: streamer,
        user: user_fixture()
      }
    end

    test "prepare_payouts/0 prepares the correct amount with withholding", %{
      streamer: streamer,
      user: user
    } do
      {:ok, _} = channel_subscription_fixture(streamer, user, "456")
      {:ok, _} = channel_subscription_fixture(streamer, user, "789")

      create_and_pay_invoice("1", "456")
      {:ok, subscription_invoice} = create_and_pay_invoice("2", "789")
      assert subscription_invoice.total_amount == 500
      assert subscription_invoice.withholding_amount == 13
      assert subscription_invoice.payout_amount == 237

      transfers = Transfers.prepare_payouts()
      paid_out_transfers = Transfers.commit_payouts(transfers)

      Enum.map(paid_out_transfers, fn {result, data} ->
        assert result == :ok
        assert data.amount == 474
      end)
    end
  end

  describe "Stripe Connecting" do
    setup do
      %{
        streamer: streamer_fixture(),
        user: user_fixture()
      }
    end

    test "start_connect/4 returns a stripe url", %{streamer: streamer} do
      assert {:ok, url} =
               StripeProvider.start_connect(
                 streamer,
                 "US",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )

      assert url =~ "https://"
      assert url =~ "dev.stripe.me/setup"

      another_streamer = streamer_fixture()

      assert {:ok, url} =
               StripeProvider.start_connect(
                 another_streamer,
                 "UK",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )

      assert url =~ "https://"
      assert url =~ "dev.stripe.me/setup"
    end

    test "start_connect/4 continues where you left off", %{streamer: streamer} do
      assert {:ok, url} =
               StripeProvider.start_connect(
                 streamer,
                 "US",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )

      refreshed_streamer = Glimesh.Accounts.get_user!(streamer.id)
      refute is_nil(refreshed_streamer.stripe_user_id)

      assert {:ok, new_url} =
               StripeProvider.start_connect(
                 refreshed_streamer,
                 "US",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )

      assert url == new_url
    end

    test "start_connect/4 wont allow you to change country", %{streamer: streamer} do
      assert {:ok, _} =
               StripeProvider.start_connect(
                 streamer,
                 "US",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )

      refreshed_streamer = Glimesh.Accounts.get_user!(streamer.id)

      assert {:error,
              "You are not allowed to setup Glimesh payouts for this country. Please contact support@glimesh.tv"} =
               StripeProvider.start_connect(
                 refreshed_streamer,
                 "UK",
                 "https://localhost/some-return",
                 "https://localhost/some-refresh"
               )
    end

    test "check_account_capabilities_and_upgrade/1 upgrades an account", %{streamer: streamer} do
      account_mock = %Stripe.Account{
        id: "1234",
        country: "US",
        capabilities: %{
          transfers: "active"
        },
        tos_acceptance: %{
          date: 1234
        }
      }

      Glimesh.Accounts.set_stripe_user_id(streamer, "1234")

      assert {:ok, user} = StripeProvider.check_account_capabilities_and_upgrade(account_mock)
      refute is_nil(user.stripe_user_id)
      assert user.is_stripe_setup
      assert user.is_tax_verified
      assert Glimesh.Accounts.can_receive_payments?(user)
    end

    test "check_account_capabilities_and_upgrade/1 upgrades an account, but does not verify taxes if outside the US",
         %{streamer: streamer} do
      account_mock = %Stripe.Account{
        id: "1234",
        country: "DE",
        capabilities: %{
          transfers: "active"
        },
        tos_acceptance: %{
          date: 1234
        }
      }

      Glimesh.Accounts.set_stripe_user_id(streamer, "1234")

      assert {:pending_taxes,
              "Your Stripe account is successfully setup, but you must provide more information regarding your income taxes."} =
               StripeProvider.check_account_capabilities_and_upgrade(account_mock)

      streamer = Glimesh.Accounts.get_user!(streamer.id)
      refute is_nil(streamer.stripe_user_id)
      assert streamer.is_stripe_setup
      refute streamer.is_tax_verified
      refute Glimesh.Accounts.can_receive_payments?(streamer)
    end

    test "check_account_capabilities_and_upgrade/1 has pending states" do
      assert {:pending_stripe,
              "Verifying that your account can receive transfers. Please check back later."} =
               StripeProvider.check_account_capabilities_and_upgrade(%Stripe.Account{
                 id: "1234",
                 country: "US",
                 capabilities: %{
                   transfers: "pending"
                 },
                 tos_acceptance: %{
                   date: 1234
                 }
               })

      assert {:pending_stripe,
              "Verifying your Terms of Service acceptance. Please check back later."} =
               StripeProvider.check_account_capabilities_and_upgrade(%Stripe.Account{
                 id: "1234",
                 country: "US",
                 capabilities: %{
                   transfers: "active"
                 },
                 tos_acceptance: %{
                   date: 0
                 }
               })

      assert {:pending_stripe, "Verifying your account details. Please check back later."} =
               StripeProvider.check_account_capabilities_and_upgrade(%Stripe.Account{
                 id: "1234",
                 country: "US",
                 capabilities: %{},
                 tos_acceptance: %{}
               })
    end
  end
end
