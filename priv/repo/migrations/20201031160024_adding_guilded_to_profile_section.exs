defmodule Glimesh.Repo.Migrations.AddingGuildedToProfileSection do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :social_guilded, :string
    end
  end
end
