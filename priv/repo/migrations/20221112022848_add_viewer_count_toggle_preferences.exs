defmodule Glimesh.Repo.Migrations.AddViewerCountTogglePreferences do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :show_viewer_count, :boolean, default: true
    end

    alter table(:user_preferences) do
      add :maximize_viewer_count, :boolean, default: true
    end
  end
end
