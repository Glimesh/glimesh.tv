defmodule Glimesh.Repo.Migrations.CreatePlatformSubscriptions do
  use Ecto.Migration

  def change do
    create table(:platform_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :stripe_subscription_id, :string
      add :stripe_product_id, :string
      add :stripe_price_id, :string
      add :stripe_current_period_end, :integer
      add :is_active, :boolean
      add :started_at, :naive_datetime
      add :ended_at, :naive_datetime

      timestamps()
    end

    alter table(:users) do
      add :stripe_customer_id, :string
    end

  end
end
