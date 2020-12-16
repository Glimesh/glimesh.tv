defmodule Glimesh.Repo.Migrations.AddVerifiedTwitter do
  use Ecto.Migration

  def change do
    create table(:user_socials) do
      add :user_id, references(:users)

      add :platform, :string
      add :identifier, :string
      add :username, :string

      timestamps()
    end

    # Platform + Identifier should be unique across the platform
    create unique_index(:user_socials, [:platform, :identifier])
  end
end
