defmodule Glimesh.Repo.Migrations.AddChatSidebarToggle do
  use Ecto.Migration

  def change do
    alter table(:user_preferences) do
      add :enable_new_channel_page, :boolean, default: false
    end
  end
end
