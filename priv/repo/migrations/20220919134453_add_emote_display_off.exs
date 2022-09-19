defmodule Glimesh.Repo.Migrations.AddEmoteDisplayOff do
  use Ecto.Migration

  def change do
      alter table(:emotes) do
        add :emote_display_off, :boolean, default: false
    end
  end
end
