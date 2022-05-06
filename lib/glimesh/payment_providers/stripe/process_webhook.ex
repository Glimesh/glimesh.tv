defmodule Glimesh.PaymentProviders.StripeProvider.ProcessWebhook do
  @moduledoc """
  Async processor for Stripe Webhooks
  """
  # credo:disable-for-this-file
  @behaviour Rihanna.Job

  alias Glimesh.PaymentProviders.StripeProvider
  alias Glimesh.Payments

  def perform([type, data]) do
    case [type, data] do
      ["account.updated", %{object: %Stripe.Account{} = account}] ->
        case StripeProvider.check_account_capabilities_and_upgrade(account) do
          {:pending_stripe, _} ->
            :ok

          {:pending_taxes, _} ->
            :ok

          other ->
            other
        end

      ["checkout.session.completed", %{object: %Stripe.Session{} = session}] ->
        if session.payment_status == "paid" do
          StripeProvider.complete_session(session)
        end

      ["invoice.created", %{object: %Stripe.Invoice{} = invoice}] ->
        case StripeProvider.create_invoice(invoice) do
          {:error_unimplemented, _} -> :ok
          other -> other
        end

      ["invoice.paid", %{object: %Stripe.Invoice{} = invoice}] ->
        case StripeProvider.pay_invoice(invoice) do
          {:error_unimplemented, _} -> :ok
          other -> other
        end

      ["invoice.payment_succeeded", %{object: %Stripe.Invoice{} = invoice}] ->
        if invoice.status == "paid" do
          Payments.process_successful_renewal(invoice.subscription, invoice.period_end)
        end

      ["customer.subscription.updated", %{object: %Stripe.Subscription{} = subscription}] ->
        case subscription.status do
          "canceled" ->
            Payments.process_unsuccessful_renewal(subscription.id)

          "unpaid" ->
            Payments.process_unsuccessful_renewal(subscription.id)

          "trialing" ->
            :ok

          "active" ->
            :ok
        end

      ["customer.subscription.deleted", %{object: %Stripe.Subscription{} = subscription}] ->
        case subscription.status do
          "canceled" ->
            Payments.process_unsuccessful_renewal(subscription.id)

          "unpaid" ->
            Payments.process_unsuccessful_renewal(subscription.id)
        end

      [type, _] ->
        {:ok, "Unhandled stripe webhook type #{type}"}
    end
  end
end
