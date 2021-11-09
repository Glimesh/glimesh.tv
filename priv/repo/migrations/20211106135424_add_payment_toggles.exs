defmodule Glimesh.Repo.Migrations.AddPaymentToggles do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :show_subscribe_button, :boolean, default: true
      add :show_donate_button, :boolean, default: true
      add :show_streamloots_button, :boolean, default: true
    end
  end
end
