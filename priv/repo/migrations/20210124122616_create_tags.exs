defmodule Glimesh.Repo.Migrations.CreateTags do
  use Ecto.Migration

  import Ecto.Query, warn: false

  def change do
    create table(:tags) do
      add :identifier, :string
      add :name, :string
      add :slug, :string

      add :icon, :string
      add :count_usage, :integer
      add :category_id, references(:categories)

      timestamps()
    end

    create unique_index(:tags, [:identifier])

    alter table(:channels) do
      add :global_tags, {:array, :integer}
      add :category_tags, {:array, :integer}
    end

    alter table(:streams) do
      add :global_tags, {:array, :integer}
      add :category_tags, {:array, :integer}
    end

    Glimesh.Repo.update_all(
      from(ch in Glimesh.Streams.Channel,
        join: cat in Glimesh.Streams.Category,
        on: cat.id == ch.category_id,
        join: parent in Glimesh.Streams.Category,
        on: parent.id == cat.parent_id,
        update: [set: [category_id: parent.id]],
        where: not is_nil(ch.category_id) and not is_nil(cat.parent_id)
      ),
      []
    )

    Glimesh.Repo.update_all(
      from(ch in Glimesh.Streams.Stream,
        join: cat in Glimesh.Streams.Category,
        on: cat.id == ch.category_id,
        join: parent in Glimesh.Streams.Category,
        on: parent.id == cat.parent_id,
        update: [set: [category_id: parent.id]],
        where: not is_nil(ch.category_id) and not is_nil(cat.parent_id)
      ),
      []
    )

    flush()

    from(c in Glimesh.Streams.Category, where: not is_nil(c.parent_id))
    |> Glimesh.Repo.delete_all()

    flush()

    alter table(:categories) do
      remove :tag_name
      remove :avatar
      remove :parent_id
    end

    create unique_index(:categories, [:name])
  end
end
