defmodule Glimesh.OauthApplications.OauthApplication do
  @moduledoc false
  use Ecto.Schema

  schema "oauth_applications" do
    field :name, :string, null: false
    field :uid, :string, null: false
    field :secret, :string, null: false, default: ""
    field :redirect_uri, :string, null: false
    field :scopes, :string, null: false, default: ""

    belongs_to :owner, Glimesh.Accounts.User

    has_many :access_tokens, Glimesh.OauthAccessTokens.OauthAccessToken,
      foreign_key: :application_id

    has_one :app, Glimesh.Apps.App

    timestamps()
  end
end
