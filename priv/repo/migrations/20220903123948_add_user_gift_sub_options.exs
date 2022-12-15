defmodule Glimesh.Repo.Migrations.AddUserGiftSubOptions do
  use Ecto.Migration

  def change do
    alter table(:user_preferences) do
      add :gift_subs_enabled, :boolean, default: true
    end
  end
end
