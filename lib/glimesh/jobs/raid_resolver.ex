defmodule Glimesh.Jobs.RaidResolver do
  @moduledoc false
  use Oban.Worker, max_attempts: 1

  require Logger

  alias Glimesh.Raids
  alias Glimesh.Streams

  @impl Oban.Worker
  def perform(%{args: %{"raiding_group_id" => raid_group} = _args}) do
    Logger.info("Performing raid for raid group: #{raid_group}")

    raid_definition = Raids.get_raid_definition(raid_group)
    participating_users = Raids.get_raid_users(raid_group)

    if raid_definition.status == :pending do
      Logger.info(
        "Starting raid with #{Enum.count(participating_users)} participants for raid group: #{raid_group}"
      )

      Streams.perform_raid_channel(
        participating_users,
        raid_definition.started_by.channel,
        raid_definition.target_channel,
        raid_group
      )

      Logger.info("Raid for group: #{raid_group} Complete!")
      {:ok, :success}
    else
      Logger.info(
        "Raid not performed for group: #{raid_group}! Raid status = #{raid_definition.status}"
      )

      {:ok, :not_correct_status}
    end
  rescue
    e ->
      Logger.error(e)
      {:error, e}
  end
end
