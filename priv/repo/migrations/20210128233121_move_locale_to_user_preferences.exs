defmodule Glimesh.Repo.Migrations.MoveLocaleToUserPreferences do
  use Ecto.Migration

  import Ecto.Query

  def change do
    alter table(:user_preferences) do
      add :locale, :string, default: "en"
    end

    flush()

    Glimesh.Repo.update_all(
      from(up in "user_preferences",
        join: u in "users",
        on: up.user_id == u.id,
        update: [set: [locale: u.locale]]
      ),
      []
    )

    alter table(:users) do
      remove :locale
    end
  end
end
