defmodule Glimesh.Repo.Migrations.ChangeOwnerForFollowersChat do
  use Ecto.Migration
  import Ecto.Query

  def up do
    rename table(:user_moderators), to: table(:channel_moderators)
    rename table(:user_moderation_log), to: table(:channel_moderation_log)

    alter table(:chat_messages) do
      add :channel_id, references(:channels)
    end

    alter table(:channel_moderators) do
      add :channel_id, references(:channels)
    end

    alter table(:channel_moderation_log) do
      add :channel_id, references(:channels)
    end

    flush()

    from(cm in "chat_messages",
      join: c in Glimesh.Streams.Channel,
      on: c.user_id == cm.streamer_id,
      update: [set: [channel_id: c.id]]
    )
    |> Glimesh.Repo.update_all([])

    from(cm in "channel_moderators",
      join: c in Glimesh.Streams.Channel,
      on: c.user_id == cm.streamer_id,
      update: [set: [channel_id: c.id]]
    )
    |> Glimesh.Repo.update_all([])

    from(cml in "channel_moderation_log",
      join: c in Glimesh.Streams.Channel,
      on: c.user_id == cml.streamer_id,
      update: [set: [channel_id: c.id]]
    )
    |> Glimesh.Repo.update_all([])

    alter table(:chat_messages) do
      remove :streamer_id
    end

    alter table(:channel_moderators) do
      remove :streamer_id
    end

    alter table(:channel_moderation_log) do
      remove :streamer_id
    end
  end

  def down do
    rename table(:channel_moderators), to: table(:user_moderators)
    rename table(:channel_moderation_log), to: table(:user_moderation_log)

    alter table(:chat_messages) do
      add :streamer_id, references(:users)
    end

    alter table(:user_moderators) do
      add :streamer_id, references(:users)
    end

    alter table(:user_moderation_log) do
      add :streamer_id, references(:users)
    end

    flush()

    from(cm in "chat_messages",
      join: c in Glimesh.Streams.Channel,
      on: c.id == cm.channel_id,
      update: [set: [streamer_id: c.user_id]]
    )
    |> Glimesh.Repo.update_all([])

    from(cm in "user_moderators",
      join: c in Glimesh.Streams.Channel,
      on: c.id == cm.channel_id,
      update: [set: [streamer_id: c.user_id]]
    )
    |> Glimesh.Repo.update_all([])

    from(cml in "user_moderation_log",
      join: c in Glimesh.Streams.Channel,
      on: c.id == cml.channel_id,
      update: [set: [streamer_id: c.user_id]]
    )
    |> Glimesh.Repo.update_all([])

    alter table(:chat_messages) do
      remove :channel_id
    end

    alter table(:user_moderators) do
      remove :channel_id
    end

    alter table(:user_moderation_log) do
      remove :channel_id
    end
  end
end
