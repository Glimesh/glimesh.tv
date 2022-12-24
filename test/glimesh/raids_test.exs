defmodule Glimesh.RaidsTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  import Glimesh.RaidingFixtures

  alias Glimesh.Repo
  alias Glimesh.Raids

  defp setup_raid_definition(_) do
    raider = streamer_fixture()
    target = streamer_fixture()
    {:ok, raid_definition} = create_raid_definition(raider, target.channel)

    %{
      raider: raider,
      target: target,
      target_channel: target.channel,
      group_id: raid_definition.group_id,
      raid_definition: raid_definition
    }
  end

  describe "Raids" do
    setup :setup_raid_definition

    test "get_raid_users should return users pending a raid", %{
      group_id: group_id,
      raid_definition: definition
    } do
      user_one = user_fixture()
      user_two = user_fixture()
      user_three = user_fixture()

      create_raid_user(user_one, definition)
      create_raid_user(user_two, definition)
      create_raid_user(user_three, definition, :cancelled)

      raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(raid_users) == 2
      assert Enum.any?(raid_users, fn raider -> raider.user.id == user_one.id end)
      assert Enum.any?(raid_users, fn raider -> raider.user.id == user_two.id end)
      refute Enum.any?(raid_users, fn raider -> raider.user.id == user_three.id end)
    end

    test "get_raid_users should ONLY return pending users", %{
      group_id: group_id,
      raid_definition: definition
    } do
      user_one = user_fixture()
      user_two = user_fixture()

      create_raid_user(user_one, definition, :cancelled)
      create_raid_user(user_two, definition, :cancelled)

      raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(raid_users) == 0
    end

    test "remove_pending_raid_user should remove a user from a raid", %{
      group_id: group_id,
      raid_definition: definition
    } do
      user_one = user_fixture()
      user_two = user_fixture()
      user_three = user_fixture()

      create_raid_user(user_one, definition)
      create_raid_user(user_two, definition)
      {:ok, create_user_three} = create_raid_user(user_three, definition, :cancelled)

      Raids.remove_pending_raid_user(group_id, user_two.id)
      Raids.remove_pending_raid_user(group_id, user_three.id)
      raid_users = Raids.get_raid_users(group_id)
      assert Enum.count(raid_users) == 1
      assert Enum.any?(raid_users, fn raider -> raider.user.id == user_one.id end)
      refute Enum.any?(raid_users, fn raider -> raider.user.id == user_two.id end)
      refute Enum.any?(raid_users, fn raider -> raider.user.id == user_three.id end)

      raid_user_three = Repo.get(Glimesh.Streams.RaidUser, create_user_three.id)
      assert raid_user_three.status == :cancelled
    end

    test "update_raid_status should update a raid to complete", %{
      group_id: group_id,
      raid_definition: definition
    } do
      user_one = user_fixture()
      user_two = user_fixture()
      user_three = user_fixture()

      {:ok, create_raid_user_one} = create_raid_user(user_one, definition)
      {:ok, create_raid_user_two} = create_raid_user(user_two, definition)
      {:ok, create_raid_user_three} = create_raid_user(user_three, definition, :cancelled)

      Raids.update_raid_status(group_id)
      updated_raid_user_one = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_one.id)
      updated_raid_user_two = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_two.id)
      updated_raid_user_three = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_three.id)
      updated_raid_definition = Repo.get(Glimesh.Streams.ChannelRaids, definition.id)

      assert updated_raid_user_one.status == :complete
      assert updated_raid_user_two.status == :complete
      assert updated_raid_definition.status == :complete
      assert updated_raid_user_three.status == :cancelled
    end

    test "update_raid_status should update a raid and pending users to cancelled", %{
      group_id: group_id,
      raid_definition: definition
    } do
      user_one = user_fixture()
      user_two = user_fixture()
      user_three = user_fixture()

      {:ok, create_raid_user_one} = create_raid_user(user_one, definition)
      {:ok, create_raid_user_two} = create_raid_user(user_two, definition)
      {:ok, create_raid_user_three} = create_raid_user(user_three, definition, :cancelled)

      Raids.update_raid_status(group_id, :cancelled)
      updated_raid_user_one = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_one.id)
      updated_raid_user_two = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_two.id)
      updated_raid_user_three = Repo.get(Glimesh.Streams.RaidUser, create_raid_user_three.id)
      updated_raid_definition = Repo.get(Glimesh.Streams.ChannelRaids, definition.id)

      assert updated_raid_user_one.status == :cancelled
      assert updated_raid_user_two.status == :cancelled
      assert updated_raid_definition.status == :cancelled
      assert updated_raid_user_three.status == :cancelled
    end

    test "get_raid_definition should retrieve a raid definition", %{group_id: group_id} do
      raid_def = Raids.get_raid_definition(group_id)
      assert not is_nil(raid_def)

      non_existing_group_id = Ecto.UUID.generate()
      non_existing_raid_def = Raids.get_raid_definition(non_existing_group_id)
      assert is_nil(non_existing_raid_def)
    end

    test "is_raid_pending should be true only if a raid is pending", %{group_id: group_id} do
      raid_def = Raids.get_raid_definition(group_id)
      assert not is_nil(raid_def)

      assert Raids.is_raid_pending?(group_id)
      Raids.update_raid_status(group_id, :complete)
      refute Raids.is_raid_pending?(group_id)

      random_uuid = Ecto.UUID.generate()
      refute Raids.is_raid_pending?(random_uuid)
    end
  end
end
