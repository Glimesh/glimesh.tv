defmodule Glimesh.Repo.Migrations.AddGiftSubscriptionSupport do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :from_user_id, references(:users), null: true

      modify :stripe_subscription_id, :string, null: true
    end
  end
end
