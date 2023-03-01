defmodule Glimesh.Repo.Migrations.RemoveOrphanedTwitterHandles do
  use Ecto.Migration

  def up do
    query = "update users set social_twitter = NULL
    where social_twitter is not null
    and not exists
      (select user_id from user_socials us
       where us.user_id = users.id
       and us.platform = 'twitter')"
    Glimesh.Repo.query!(query)
  end

  def down, do: :ok
end
