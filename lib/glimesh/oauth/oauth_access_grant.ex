defmodule Glimesh.OauthAccessGrants.OauthAccessGrant do
  @moduledoc false
  use Ecto.Schema

  schema "oauth_access_grants" do
    field :token, :string, null: false
    field :expires_in, :integer, null: false
    field :redirect_uri, :string, null: false
    field :revoked_at, :utc_datetime
    field :scopes, :string

    belongs_to :resource_owner, Glimesh.Accounts.User
    belongs_to :application, Glimesh.OauthApplications.OauthApplication

    timestamps()
  end
end
