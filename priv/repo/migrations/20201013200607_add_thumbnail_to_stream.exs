defmodule Glimesh.Repo.Migrations.AddThumbnailToStream do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :thumbnail, :string
    end
  end
end
