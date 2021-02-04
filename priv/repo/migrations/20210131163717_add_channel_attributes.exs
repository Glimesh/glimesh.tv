defmodule Glimesh.Repo.Migrations.AddChannelAttributes do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :mature_content, :boolean
    end

    alter table(:user_preferences) do
      add :show_mature_content, :boolean
    end
  end
end
