defmodule Glimesh.Repo.Migrations.ClientsRefreshTokens do
  use Ecto.Migration

  def change do
  end

  # Migrated previously
  # def change do
  #   # 20210904185118_add_public_refresh_token_to_clients.exs
  #   alter table(:oauth_clients) do
  #     add :public_refresh_token, :boolean, null: false, default: false
  #   end

  #   # 20210914115259_add_refresh_token_ttl_to_clients.exs
  #   alter table(:oauth_clients) do
  #     add :refresh_token_ttl, :integer, null: false, default: "2592000"
  #   end
  # end
end
