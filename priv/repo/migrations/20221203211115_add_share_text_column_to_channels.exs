defmodule Glimesh.Repo.Migrations.AddShareTextColumnToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :share_text, :string, default: "Come and enjoy this #Glimesh stream with me!"
    end
  end
end
