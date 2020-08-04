defmodule Glimesh.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string
      add :slug, :string
      add :body_md, :text
      add :body_html, :text
      add :description, :string
      add :published, :boolean, default: false, null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:articles, [:slug])
  end
end
