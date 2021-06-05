defmodule Glimesh.Repo.Migrations.AddChannelEmotePrefix do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :emote_prefix, :string
    end

    create unique_index(:channels, [:emote_prefix])
  end
end
