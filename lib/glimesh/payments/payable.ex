defmodule Glimesh.Payments.Payable do
  @moduledoc """
  Generic storage for anytime we're responsible to pay a user.
  Designed so we can accept Stripe Checkout Sessions, Stripe Invoices, and in the long-term future Paypal transactions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "payables" do
    field :type, :string

    belongs_to :user, Glimesh.Accounts.User
    belongs_to :streamer, Glimesh.Accounts.User

    # Generic fields to allow for any payable configuration
    field :external_source, :string
    field :external_reference, :string
    field :status, :string

    # These fields are calculated by us
    # Cents of course...
    field :total_amount, :integer
    field :external_fees, :integer
    field :our_fees, :integer
    field :withholding_amount, :integer
    field :payout_amount, :integer

    # These fields are what actually happened
    field :user_paid_at, :naive_datetime
    field :streamer_payout_at, :naive_datetime
    field :streamer_payout_amount, :integer
    field :stripe_transfer_id, :string

    timestamps()
  end

  @doc false
  def create_changeset(payable, attrs) do
    payable
    |> cast(attrs, [
      :type,
      :external_source,
      :external_reference,
      :status,
      :total_amount,
      :external_fees,
      :our_fees,
      :withholding_amount,
      :payout_amount,
      :user_paid_at,
      :streamer_payout_at,
      :streamer_payout_amount,
      :stripe_transfer_id
    ])
    |> validate_inclusion(:type, ["donation", "subscription", "gift_subscription"])
    |> validate_inclusion(:external_source, ["stripe"])
    |> validate_inclusion(:status, ["created", "paid", "paidout"])
    |> put_assoc(:user, attrs.user)
    |> maybe_put_assoc(:streamer, Map.get(attrs, :streamer, nil))
    |> validate_required([
      :type,
      :external_source,
      :external_reference,
      :status,
      :total_amount
    ])
    |> unique_constraint(:external_source_reference, name: :external_source_reference)
  end

  def update_changeset(payable, attrs) do
    payable
    |> cast(attrs, [
      :status,
      :total_amount,
      :external_fees,
      :our_fees,
      :withholding_amount,
      :payout_amount,
      :user_paid_at,
      :streamer_payout_at,
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
