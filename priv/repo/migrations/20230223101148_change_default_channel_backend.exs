defmodule Glimesh.Repo.Migrations.ChangeDefaultChannelBackend do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      modify :backend, :string, default: "whep"
    end

    execute "update channels set backend = 'whep';"
  end
end
