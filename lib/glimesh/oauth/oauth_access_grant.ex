defmodule Glimesh.OauthAccessGrants.OauthAccessGrant do
  @moduledoc false
  use Ecto.Schema
  use ExOauth2Provider.AccessGrants.AccessGrant, otp_app: :glimesh

  schema "oauth_access_grants" do
    access_grant_fields()

    timestamps()
  end
end
