defmodule Glimesh.ApiFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glimesh.Accounts` context.
  """

  def app_fixture(user, redirect_uri \\ "https://glimesh.dev/") do
    Glimesh.Apps.create_app(user, %{
      name: "Test Client",
      description: "For testing!",
      client: %{
        redirect_uris: redirect_uri
      }
    })
  end
end
