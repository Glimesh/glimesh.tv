defmodule Glimesh.OauthAccessTokens.OauthAccessToken do
  @moduledoc false
  use Ecto.Schema
  use ExOauth2Provider.AccessTokens.AccessToken, otp_app: :glimesh

  schema "oauth_access_tokens" do
    field :token, :string, null: false
    field :refresh_token, :string
    field :expires_in, :integer
    field :revoked_at, :utc_datetime
    field :scopes, :string
    field :previous_refresh_token, :string, null: false, default: ""

    belongs_to :resource_owner, Glimesh.Accounts.User
    belongs_to :application, Glimesh.OauthApplications.OauthApplication

    timestamps()
  end
end
