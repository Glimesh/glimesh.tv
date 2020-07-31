defmodule Glimesh.Payments.PlatformSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :stripe_subscription_id,
    :stripe_product_id,
    :stripe_price_id,
    :stripe_current_period_end,
    :is_active,
    :started_at,
    :ended_at
  ]}
  schema "platform_subscriptions" do
    belongs_to :user, Glimesh.Accounts.User

    field :stripe_subscription_id, :string
    field :stripe_product_id, :string
    field :stripe_price_id, :string
    field :stripe_current_period_end, :integer

    field :is_active, :boolean
    field :started_at, :naive_datetime
    field :ended_at, :naive_datetime

    timestamps()
  end

  @doc false
  def create_changeset(platform_subscription, attrs) do
    platform_subscription
    |> cast(attrs, [:stripe_subscription_id, :stripe_product_id, :stripe_price_id, :stripe_current_period_end, :started_at, :ended_at, :is_active])
    |> put_assoc(:user, attrs.user)
    |> validate_required([:user, :stripe_subscription_id, :stripe_product_id, :stripe_price_id, :stripe_current_period_end, :started_at, :ended_at])
  end

  @doc false
  def update_changeset(platform_subscription, attrs) do
    platform_subscription
    |> cast(attrs, [:stripe_current_period_end, :ended_at, :is_active])
    |> validate_required([:stripe_current_period_end, :ended_at, :is_active])
  end
end
