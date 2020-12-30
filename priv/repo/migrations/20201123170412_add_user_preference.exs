defmodule Glimesh.Repo.Migrations.AddUserPreferences do
  use Ecto.Migration
  use Ecto.Schema

  import Ecto.Query, warn: false

  alias Glimesh.Accounts.UserPreference

  def change do
    create table(:user_preferences) do
      add :user_id, references(:users), null: false

      add :site_theme, :string, default: "dark"

      timestamps()
    end

    flush()

    users = Glimesh.Repo.all(from u in "users", select: [:id])

    Enum.each(users, fn user ->
      %UserPreference{
        user: user
      }
      |> UserPreference.changeset(%{})
      |> Glimesh.Repo.insert()
    end)
  end
end
