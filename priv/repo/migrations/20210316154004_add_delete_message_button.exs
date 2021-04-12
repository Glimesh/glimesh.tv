defmodule Glimesh.Repo.Migrations.AddDeleteMessageButton do
  use Ecto.Migration

  def change do
    alter table(:channel_moderators) do
      add :can_delete, :boolean, default: false
    end
  end
end
