defmodule Glimesh.Repo.Migrations.AddChatRulesToChannel do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :chat_rules_md, :text
      add :chat_rules_html, :text
    end
  end
end
