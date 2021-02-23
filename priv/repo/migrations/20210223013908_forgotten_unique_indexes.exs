defmodule Glimesh.Repo.Migrations.ForgottenUniqueIndexes do
  use Ecto.Migration

  def change do
    # Category Slugs
    create index("categories", [:slug], unique: true)

    # Channel Moderators
    create index("channel_moderators", [:channel_id, :user_id], unique: true)

    # User Channels
    create index("channels", [:user_id], unique: true)

    # Channel Bans
    create index("channel_bans", [:channel_id, :user_id], unique: true, where: "expires_at is not null", name: :channel_bans_unique_index_non_null)
    create index("channel_bans", [:channel_id, :user_id], unique: true, where: "expires_at is null", name: :channel_bans_unique_index_null)

    # User Preferences
    create index("user_preferences", [:user_id], unique: true)
  end
end
