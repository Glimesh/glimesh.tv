defmodule Glimesh.Repo.Migrations.FixDiscordInviteLinks do
  use Ecto.Migration

  import Ecto.Query

  def change do
    users =
      Glimesh.Repo.all(
        from(u in Glimesh.Accounts.User,
          where: not is_nil(u.social_discord)
        )
      )

    Enum.each(users, fn user ->
      {:ok, new_social_discord} =
        Glimesh.Accounts.Profile.strip_invite_link_from_discord_url(user.social_discord)

      changeset =
        user
        |> Glimesh.Accounts.User.profile_changeset(%{social_discord: new_social_discord})

      Glimesh.Repo.update!(changeset)
    end)
  end
end
