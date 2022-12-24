defmodule Glimesh.Raids do
  @moduledoc false

  alias Ecto.Multi
  alias Glimesh.Repo
  alias Glimesh.Streams.ChannelRaids
  alias Glimesh.Streams.RaidUser

  import Ecto.Query, warn: false

  def get_raid_users(raid_group_id) do
    from(ru in RaidUser,
      where: ru.group_id == ^raid_group_id,
      where: ru.status == :pending,
      preload: [:group, :user]
    )
    |> Repo.all()
  end

  def remove_pending_raid_user(raid_group_id, user_id) do
    from(ru in RaidUser,
      where: ru.group_id == ^raid_group_id,
      where: ru.user_id == ^user_id,
      where: ru.status == :pending
    )
    |> Repo.delete_all()
  end

  def update_raid_status(raid_group_id, status \\ :complete) do
    Ecto.Multi.new()
    |> Multi.update_all(:raid_users, update_raid_users_status(raid_group_id, status), [])
    |> Multi.update_all(
      :raid_definition,
      update_raid_definition_status(raid_group_id, status),
      []
    )
    |> Repo.transaction()
  end

  def get_raid_definition(raid_group_id) do
    from(cr in ChannelRaids,
      where: cr.group_id == ^raid_group_id,
      preload: [target_channel: [:user, :stream], started_by: [channel: [:user]]]
    )
    |> Repo.one()
  end

  def is_raid_pending?(raid_group_id) do
    raid_definition = get_raid_definition(raid_group_id)

    not is_nil(raid_definition) and raid_definition.status == :pending
  end

  defp update_raid_definition_status(raid_group_id, status) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(cr in ChannelRaids,
      update: [set: [status: ^status, updated_at: ^now]],
      where: cr.group_id == ^raid_group_id
    )
  end

  defp update_raid_users_status(raid_group_id, status) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(ru in RaidUser,
      update: [set: [status: ^status, updated_at: ^now]],
      where: ru.group_id == ^raid_group_id,
      where: ru.status == :pending
    )
  end
end
