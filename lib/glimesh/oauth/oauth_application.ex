defmodule Glimesh.OauthApplications.OauthApplication do
  @moduledoc false
  use Ecto.Schema
  use ExOauth2Provider.Applications.Application, otp_app: :glimesh

  schema "oauth_applications" do
    application_fields()

    has_one :app, Glimesh.Apps.App

    timestamps()
  end
end
