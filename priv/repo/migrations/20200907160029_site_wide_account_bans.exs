defmodule :"Elixir.Glimesh.Repo.Migrations.SiteWideAccountBans" do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_banned, :boolean, default: false
      add :ban_reason, :text
    end
  end
end
