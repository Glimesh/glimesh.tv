defmodule Glimesh.Repo.Migrations.AddUserCanPaymentsFlag do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :can_payments, :boolean, default: false
    end
  end
end
