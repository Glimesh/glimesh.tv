defmodule Glimesh.Repo.Migrations.AddStreamingBackendToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :backend, :string, default: "ftl"
    end
  end
end
