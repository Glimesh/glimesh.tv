defmodule Glimesh.Repo.Migrations.AddRefreshTokenTtlToClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :refresh_token_ttl, :integer, null: false, default: "2592000"
    end

    alter table(:clients) do
      modify :refresh_token_ttl, :integer, null: false
    end
  end
end
