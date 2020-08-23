defmodule Glimesh.Repo.Migrations.ApiSpecDatabase do
  use Ecto.Migration

  def change do
    rename table(:stream_metadata), to: table(:channels)

    alter table(:channels) do
      add :status, :string
      add :language, :string
      add :thumbnail, :string
      add :stream_key, :string
    end

    rename table(:channels), :stream_title, to: :title
    rename table(:channels), :streamer_id, to: :user_id

    create table(:streams) do
      add :channel_id, references(:channels)

      add :title, :string
      add :category_id, references(:categories)

      add :started_at, :naive_datetime
      add :ended_at, :naive_datetime

      add :count_viewers, :integer
      add :count_chatters, :integer

      add :peak_viewers, :integer
      add :peak_chatters, :integer
      add :avg_viewers, :integer
      add :avg_chatters, :integer
      add :new_subscribers, :integer
      add :resub_subscribers, :integer

      timestamps()
    end
  end
end
