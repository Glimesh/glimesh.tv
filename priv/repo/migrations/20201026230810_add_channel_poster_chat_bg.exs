defmodule Glimesh.Repo.Migrations.AddChannelPosterChatBg do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :poster, :string
      add :chat_bg, :string
    end
  end
end
