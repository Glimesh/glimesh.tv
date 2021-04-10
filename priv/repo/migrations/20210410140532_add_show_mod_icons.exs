defmodule Glimesh.Repo.Migrations.AddShowModIcons do
  use Ecto.Migration

  def change do
    alter table(:user_preferences) do
      add :show_mod_icons, :boolean, default: true
    end
  end
end
