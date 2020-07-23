defmodule Glimesh.Repo.Migrations.AddUserModeration do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_admin, :boolean
    end

    alter table(:chat_messages) do
      add :is_visible, :boolean, default: true
    end

    create table(:user_moderators) do
      add :streamer_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :can_short_timeout, :boolean
      add :can_long_timeout, :boolean
      add :can_un_timeout, :boolean
      add :can_ban, :boolean
      add :can_unban, :boolean

      timestamps()
    end

    create table(:user_moderation_log) do
      add :streamer_id, references(:users, on_delete: :delete_all), null: false
      add :moderator_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :action, :string

      timestamps()
    end
  end
end
