defmodule Glimesh.Repo.Migrations.FixApplicationErrorsForBoruta do
  use Ecto.Migration

  def change do
    Glimesh.Apps.list_apps()
    |> Glimesh.Repo.preload([:oauth_application, :user])
    |> Enum.each(fn x ->
      Glimesh.Apps.update_app(x.user, x, %{client: %{name: x.name, redirect_uris: x.oauth_application.redirect_uri}})
    end)
  end
end
