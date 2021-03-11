defmodule Glimesh.Repo.Migrations.AddSubscribedMessage do
  use Ecto.Migration

  def change do
    alter table(:chat_messages) do
      add :is_subscription_message, :boolean, default: false
    end
  end
end
