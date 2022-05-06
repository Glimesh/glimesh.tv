defmodule Glimesh.Payments.Subscription do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :stripe_subscription_id,
             :stripe_product_id,
             :stripe_price_id,
             :stripe_current_period_end,
             :price,
             :fee,
             :payout,
             :product_name,
             :is_active,
             :started_at,
             :ended_at
           ]}
  schema "subscriptions" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :from_user, Glimesh.Accounts.User
    belongs_to :streamer, Glimesh.Accounts.User

    field :stripe_subscription_id, :string
    field :stripe_product_id, :string
    field :stripe_price_id, :string
    field :stripe_current_period_end, :integer
    field :price, :integer
    field :fee, :integer
    field :payout, :integer
    field :product_name, :string

    field :is_active, :boolean
    field :is_canceling, :boolean
    field :started_at, :naive_datetime
    field :ended_at, :naive_datetime

    has_many :invoices, Glimesh.Payments.SubscriptionInvoice

    timestamps()
  end

  @doc false
  def create_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :stripe_subscription_id,
      :stripe_product_id,
      :stripe_price_id,
      :stripe_current_period_end,
      :price,
      :fee,
      :payout,
      :product_name,
      :started_at,
      :ended_at,
      :is_active,
      :is_canceling
    ])
    |> put_assoc(:user, attrs.user)
    |> maybe_put_assoc(:streamer, Map.get(attrs, :streamer, nil))
    |> maybe_put_assoc(:from_user, Map.get(attrs, :from_user, nil))
    |> validate_required([
      :user,
      :stripe_product_id,
      :stripe_price_id,
      :stripe_current_period_end,
      :price,
      :fee,
      :payout,
      :product_name,
      :started_at,
      :ended_at
    ])
  end

  @doc false
  def update_changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :stripe_subscription_id,
      :stripe_current_period_end,
      :ended_at,
      :is_active,
      :is_canceling
    ])
    |> validate_required([:stripe_current_period_end, :ended_at, :is_active])
  end

  def maybe_put_assoc(changeset, key, value) do
    if value do
      changeset |> put_assoc(key, value)
    else
      changeset
    end
  end
end
