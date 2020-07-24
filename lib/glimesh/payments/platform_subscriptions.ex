defmodule Glimesh.Payments.PlatformSubscriptions do
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform_subscriptions" do
    belongs_to :user, User

    field :stripe_product_id, :string
    field :is_active, :boolean

    field :started_at, :naive_datetime
    field :ended_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(platform_subscriptions, attrs) do
    platform_subscriptions
    |> cast(attrs, [:stripe_product_id, :started_at, :ended_at])
    |> validate_required([:user, :stripe_product_id, :started_at, :ended_at])
  end
end
