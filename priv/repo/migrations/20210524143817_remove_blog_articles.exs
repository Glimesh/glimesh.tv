defmodule Glimesh.Repo.Migrations.RemoveBlogArticles do
  use Ecto.Migration

  def change do
    drop table(:articles)
  end
end
