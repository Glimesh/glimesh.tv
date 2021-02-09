defmodule Glimesh.Repo.Migrations.RenameStreamKeys do
  use Ecto.Migration

  def change do
    rename table(:channels), :stream_key, to: :hmac_key
  end
end
