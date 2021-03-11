defmodule Glimesh.Payments.SubscriptionInvoice do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "subscription_invoices" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :streamer, Glimesh.Accounts.User
    belongs_to :subscription, Glimesh.Payments.Subscription

    field :stripe_invoice_id, :string
    field :stripe_status, :string

    # These fields are calculated by us
    # Total after discounts and taxes.
    field :total_amount, :integer
    # payout_amount = total_amount - withholding_amount
    field :withholding_amount, :integer
    field :payout_amount, :integer

    # These fields are what actually happened
    field :user_paid, :boolean, default: false
    field :streamer_paidout, :boolean, default: false
    field :streamer_payout_amount, :integer
    field :stripe_transfer_id, :string

    timestamps()
  end

  @doc false
  def create_changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :stripe_invoice_id,
      :stripe_status,
      :total_amount,
      :withholding_amount,
      :payout_amount,
      :user_paid,
      :streamer_paidout,
      :streamer_payout_amount,
      :stripe_transfer_id
    ])
    |> put_assoc(:user, attrs.user)
    |> put_assoc(:subscription, attrs.subscription)
    |> maybe_put_assoc(:streamer, Map.get(attrs, :streamer, nil))
    |> validate_required([
      :stripe_invoice_id
    ])
    |> unique_constraint(:stripe_invoice_id)
  end

  def update_changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :stripe_invoice_id,
      :stripe_status,
      :total_amount,
      :withholding_amount,
      :payout_amount,
      :user_paid,
      :streamer_paidout,
      :streamer_payout_amount,
      :stripe_transfer_id
    ])
  end

  def maybe_put_assoc(changeset, key, value) do
    if value do
      changeset |> put_assoc(key, value)
    else
      changeset
    end
  end
end
