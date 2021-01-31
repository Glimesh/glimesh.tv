defmodule Glimesh.Repo.Migrations.AddChannelAttributes do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :date_of_birth, :date
    end

    alter table(:channels) do
      add :adult_content, :boolean
    end

    alter table(:user_preferences) do
      add :show_adult_content, :boolean
    end
  end
end
