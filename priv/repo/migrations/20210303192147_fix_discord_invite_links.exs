defmodule Glimesh.Repo.Migrations.FixDiscordInviteLinks do
  use Ecto.Migration

  import Ecto.Query

  def change do
    users =
      Glimesh.Repo.all(
        from(u in "users",
          select: %Glimesh.Accounts.User{id: u.id, social_discord: u.social_discord}
        )
      )

    Enum.each(users, fn user ->
      if user.social_discord do
        case Glimesh.Accounts.Profile.strip_invite_link_from_discord_url(user.social_discord) do
          {:ok, new_social_discord} ->
            changeset =
              user
              |> Ecto.Changeset.change()
              |> Ecto.Changeset.put_change(:social_discord, new_social_discord)

            Glimesh.Repo.update!(changeset)

          _ ->
            nil
        end
      end
    end)
  end
end
