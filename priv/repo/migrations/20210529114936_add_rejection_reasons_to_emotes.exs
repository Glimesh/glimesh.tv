defmodule Glimesh.Repo.Migrations.AddRejectionReasonsToEmotes do
  use Ecto.Migration

  def change do
    alter table(:emotes) do
      add :rejected_at, :naive_datetime, default: nil
      add :rejected_reason, :string
    end

    rename table(:emotes), :approved_by, to: :reviewed_by_id
  end
end
