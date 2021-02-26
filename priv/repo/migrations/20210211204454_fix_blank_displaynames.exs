defmodule Glimesh.Repo.Migrations.FixBlankDisplaynames do
  use Ecto.Migration

  import Ecto.Query

  def change do
    Glimesh.Repo.update_all(
      from(u in "users",
        where: is_nil(u.displayname),
        update: [set: [displayname: u.username]]
      ),
      []
    )
  end
end
