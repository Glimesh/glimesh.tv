defmodule Glimesh.Repo.Migrations.AddEditorFlagToModerators do
  use Ecto.Migration

  def change do
    alter table(:channel_moderators) do
      add :is_editor, :boolean, default: false
    end

    alter table(:channel_moderation_log) do
      modify :user_id, :bigint, null: true, from: {:bigint, null: false}
    end
  end
end
