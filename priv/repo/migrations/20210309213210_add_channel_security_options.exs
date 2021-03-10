defmodule Glimesh.Repo.Migrations.AddChannelSecurityOptions do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :require_confirmed_email, :boolean, default: false
      add :minimum_account_age, :integer, default: 0
    end
  end
end
