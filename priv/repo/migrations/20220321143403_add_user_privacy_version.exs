defmodule Glimesh.Repo.Migrations.AddUserPrivacyVersion do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :privacy_policy_version, :naive_datetime, default: nil
    end
  end
end
