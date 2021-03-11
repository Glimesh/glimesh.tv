defmodule Glimesh.Repo.Migrations.AddChatTimestamps do
  use Ecto.Migration

  def change do
    alter table(:user_preferences) do
      add :show_timestamps, :boolean, default: false
    end
  end
end
