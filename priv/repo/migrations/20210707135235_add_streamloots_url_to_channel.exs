defmodule Glimesh.Repo.Migrations.AddStreamlootsUrlToChannel do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :streamloots_url, :string
    end
  end
end
