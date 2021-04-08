defmodule Glimesh.Repo.Migrations.CreateSubcategories do
  use Ecto.Migration

  def change do
    create table(:subcategories) do
      add :category_id, references(:categories)
      add :name, :string
      add :slug, :string

      add :user_created, :boolean
      add :source, :string, default: nil
      add :source_id, :string

      add :background_image, :string

      timestamps()
    end

    create unique_index(:subcategories, [:category_id, :slug])
    create unique_index(:subcategories, [:source, :source_id])

    alter table(:channels) do
      add :subcategory_id, references(:subcategories)
    end

    alter table(:streams) do
      add :subcategory_id, references(:subcategories)
    end
  end
end
