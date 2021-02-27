defmodule Glimesh.Repo.Migrations.AddIsCancellingToSubs do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :is_canceling, :boolean
    end
  end
end
