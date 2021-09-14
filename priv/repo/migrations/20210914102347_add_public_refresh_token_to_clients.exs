defmodule Glimesh.Repo.Migrations.AddPublicRefreshTokenToClients do
  use Ecto.Migration

  import Ecto.Query

  def change do
    alter table(:clients) do
      add :public_refresh_token, :boolean, null: false, default: false
    end

    flush()

    Glimesh.Repo.update_all(
      from(c in "clients",
        update: [set: [public_refresh_token: true]]
      ),
      []
    )
  end
end
