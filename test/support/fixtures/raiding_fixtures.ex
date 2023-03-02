defmodule Glimesh.RaidingFixtures do
  def create_raid_definition(
        %Glimesh.Accounts.User{} = raider,
        %Glimesh.Streams.Channel{} = target_channel
      ) do
    group_id = Ecto.UUID.generate()
    {:ok, binary_group_id} = Ecto.UUID.cast(group_id)

    %Glimesh.Streams.ChannelRaids{started_by: raider, target_channel: target_channel}
    |> Glimesh.Streams.ChannelRaids.changeset(%{group_id: binary_group_id, status: :pending})
    |> Glimesh.Repo.insert()
  end

  def create_raid_users(user_list, group_id) do
    user_list
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {user, index}, multi ->
      changeset =
        %Glimesh.Streams.RaidUser{user: user, group_id: group_id}
        |> Glimesh.Streams.RaidUser.changeset(%{status: :pending})

      Ecto.Multi.insert(multi, {:raid_user, index}, changeset)
    end)
    |> Glimesh.Repo.transaction()
  end

  def create_raid_user(
        %Glimesh.Accounts.User{} = user,
        %Glimesh.Streams.ChannelRaids{} = group,
        status \\ :pending
      ) do
    %Glimesh.Streams.RaidUser{user: user, group: group}
    |> Glimesh.Streams.RaidUser.changeset(%{status: status})
    |> Glimesh.Repo.insert()
  end
end
