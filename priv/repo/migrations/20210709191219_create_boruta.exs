defmodule Glimesh.Repo.Migrations.CreateBoruta do
  use Ecto.Migration

  def change do
    create table(:clients, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, default: "", null: false)
      add(:secret, :string, null: false)
      add(:redirect_uris, {:array, :string}, default: [], null: false)
      add(:scope, :string)
      add(:authorize_scope, :boolean, default: false, null: false)
      add(:supported_grant_types, {:array, :string}, default: [], null: false)
      add(:authorization_code_ttl, :integer, null: false)
      add(:access_token_ttl, :integer, null: false)
      add(:pkce, :boolean, default: false, null: false)
      add(:public_key, :text, null: false)
      add(:private_key, :text, null: false)
      # Private field added exclusively for us:
      add(:old_uid, :string, default: nil)

      timestamps()
    end

    create table(:tokens, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:value, :string)
      add(:refresh_token, :string)
      add(:expires_at, :integer)
      add(:redirect_uri, :string)
      add(:state, :string)
      add(:scope, :string)
      add(:revoked_at, :utc_datetime_usec)
      add(:code_challenge_hash, :string)
      add(:code_challenge_method, :string)

      add(:client_id, references(:clients, type: :uuid, on_delete: :nilify_all))
      add(:sub, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:scopes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :label, :string
      add :name, :string
      add :public, :boolean, default: false, null: false

      timestamps()
    end

    create table(:clients_scopes) do
      add(:client_id, references(:clients, type: :uuid, on_delete: :delete_all))
      add(:scope_id, references(:scopes, type: :uuid, on_delete: :delete_all))
    end

    create unique_index(:clients, [:id, :secret])
    create index("tokens", [:value])
    create unique_index("tokens", [:client_id, :value])
    create unique_index("tokens", [:client_id, :refresh_token])
    create unique_index("scopes", [:name])

    # Glimesh Specific
    alter table(:apps) do
      add(:client_id, references(:clients, type: :uuid))
    end
    create unique_index(:apps, [:client_id])
  end
end
