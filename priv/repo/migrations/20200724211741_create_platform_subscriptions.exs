defmodule Glimesh.Repo.Migrations.CreatePlatformSubscriptions do
  use Ecto.Migration

  def change do
    create table(:platform_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :stripe_product_id, :string
      add :is_active, :boolean
      add :started_at, :naive_datetime
      add :ended_at, :naive_datetime

      timestamps()
    end

  end
end
