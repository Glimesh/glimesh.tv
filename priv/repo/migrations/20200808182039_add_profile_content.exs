defmodule Glimesh.Repo.Migrations.AddProfileContent do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :youtube_intro_url, :string
      add :profile_content_md, :text
      add :profile_content_html, :text
    end
  end
end
