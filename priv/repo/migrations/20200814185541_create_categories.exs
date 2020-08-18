defmodule Glimesh.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :tag_name, :string
      add :slug, :string
      add :avatar, :string
      add :parent_id, references(:categories, on_delete: :delete_all), null: true

      timestamps()
    end

    create unique_index(:categories, [:slug, :parent_id])
    create unique_index(:categories, [:tag_name])

    alter table(:stream_metadata) do
      add :category_id, references(:categories, on_delete: :nilify_all), null: true
    end
  end
end
