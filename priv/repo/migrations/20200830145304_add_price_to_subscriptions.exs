defmodule Glimesh.Repo.Migrations.AddPriceToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :price, :integer
      add :product_name, :string
    end
  end
end
