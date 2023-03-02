defmodule Glimesh.Jobs.RaidResolverTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  import Glimesh.RaidingFixtures

  alias Ecto.UUID
  alias Glimesh.Repo
  alias Glimesh.Streams
  alias Glimesh.Raids
  alias Glimesh.Jobs.RaidResolver

  defp setup_raid(_) do
    raider = streamer_fixture(%{}, %{status: "live"})
    target = streamer_fixture(%{}, %{status: "live"})

    Streams.start_stream(raider.channel)

    raider_with_stream =
      Glimesh.Accounts.get_user!(raider.id)
      |> Glimesh.Repo.preload(channel: [:category, :subcategory, :tags, :stream])

    Streams.start_stream(target.channel)

    target_with_stream =
      Glimesh.Accounts.get_user!(target.id)
      |> Glimesh.Repo.preload(channel: [:category, :subcategory, :tags, :stream])

    {:ok, raid_definition} =
      create_raid_definition(raider_with_stream, target_with_stream.channel)

    user_one = user_fixture()
    user_two = user_fixture()
    user_three = user_fixture()

    {:ok, raid_user_one} = create_raid_user(user_one, raid_definition)
    {:ok, raid_user_two} = create_raid_user(user_two, raid_definition)
    {:ok, cancelled_raid_user} = create_raid_user(user_three, raid_definition, :cancelled)

    %{
      raider: raider_with_stream,
      target_channel: target_with_stream.channel,
      target: target_with_stream,
      group_id: raid_definition.group_id,
      raid_definition: raid_definition,
      raid_user_one: raid_user_one,
      raid_user_two: raid_user_two,
      cancelled_raid_user: cancelled_raid_user
    }
  end

  describe "Raid Resolver Job start raiding tasks" do
    setup :setup_raid

    test "raid job completes a raid", %{
      group_id: group_id,
      raid_definition: definition,
      raid_user_one: user_one,
      raid_user_two: user_two,
      cancelled_raid_user: cancelled_user
    } do
      assert {:ok, :success} = RaidResolver.perform(%{args: %{"raiding_group_id" => group_id}})

      pending_raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(pending_raid_users) == 0

      updated_raid_user_one = Repo.get(Glimesh.Streams.RaidUser, user_one.id)
      updated_raid_user_two = Repo.get(Glimesh.Streams.RaidUser, user_two.id)
      updated_cancelled_raid_user = Repo.get(Glimesh.Streams.RaidUser, cancelled_user.id)
      updated_raid_definition = Repo.get(Glimesh.Streams.ChannelRaids, definition.id)

      assert updated_raid_user_one.status == :complete
      assert updated_raid_user_two.status == :complete
      assert updated_cancelled_raid_user.status == :cancelled
      assert updated_raid_definition.status == :complete
    end

    test "raid job cancelled by streamer", %{
      group_id: group_id,
      raid_definition: definition,
      raid_user_one: user_one,
      raid_user_two: user_two,
      cancelled_raid_user: cancelled_user
    } do
      Raids.update_raid_status(group_id, :cancelled)
      updated_raid_definition = Repo.get(Glimesh.Streams.ChannelRaids, definition.id)

      assert {:ok, :not_correct_status} =
               RaidResolver.perform(%{args: %{"raiding_group_id" => group_id}})

      pending_raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(pending_raid_users) == 0

      updated_raid_user_one = Repo.get(Glimesh.Streams.RaidUser, user_one.id)
      updated_raid_user_two = Repo.get(Glimesh.Streams.RaidUser, user_two.id)
      updated_cancelled_raid_user = Repo.get(Glimesh.Streams.RaidUser, cancelled_user.id)

      assert updated_raid_user_one.status == :cancelled
      assert updated_raid_user_two.status == :cancelled
      assert updated_cancelled_raid_user.status == :cancelled
      assert updated_raid_definition.status == :cancelled
    end

    test "raid group doesn't exist" do
      group_id = UUID.generate()
      assert {:error, _} = RaidResolver.perform(%{args: %{"raiding_group_id" => group_id}})

      pending_raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(pending_raid_users) == 0
    end
  end
end
