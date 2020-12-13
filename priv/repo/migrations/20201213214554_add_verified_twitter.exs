defmodule Glimesh.Repo.Migrations.AddVerifiedTwitter do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :verified_twitter, :string
    end
  end
end
