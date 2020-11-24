defmodule Glimesh.Repo.Migrations.AddUserSettings do
  use Ecto.Migration
  use Ecto.Schema

  import Ecto.Query, only: [from: 1]

  alias Glimesh.Accounts.UserSetting

  def change do
    create table(:user_settings) do
      add :user_id, references(:users), null: false

      add :light_mode, :boolean, default: false

      timestamps()
    end

    flush()

    users = Glimesh.Repo.all(from u in Glimesh.Accounts.User)

    Enum.each(users, fn(user) ->
      %UserSetting{
        user: user
      }
      |> UserSetting.changeset(%{})
      |> Glimesh.Repo.insert()
      end)
  end
end
