defmodule Glimesh.Repo.Migrations.AddTfaContent do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tfa_token, :string
    end
  end
end
