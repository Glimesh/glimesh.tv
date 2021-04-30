defmodule Glimesh.Repo.Migrations.AddEmotesToDatabase do
  use Ecto.Migration

  def change do
    create table(:emotes) do
      add :emote, :string
      add :channel_id, references(:channels)
      add :animated, :boolean

      add :approved_at, :naive_datetime, default: nil
      add :approved_by, references(:users), default: nil

      add :png_file, :string
      add :svg_file, :string
      add :gif_file, :string

      timestamps()
    end

    create unique_index(:emotes, [:emote])
  end
end
