defmodule Glimesh.FactoryTest do
  use Glimesh.DataCase
  import Glimesh.Factory

  test "user factory works" do
    assert %Glimesh.Accounts.User{} = insert(:user)
  end

  test "user factory works with following and follower" do
    user = insert(:user)
           |> user_with_follow
           |> user_with_follower

    refute user |> Glimesh.Repo.preload(:followers) |> Map.get(:followers) |> Enum.empty?
    refute user |> Glimesh.Repo.preload(:following) |> Map.get(:following) |> Enum.empty?
  end

  test "channel factory works" do
    assert %Glimesh.Streams.Channel{} = insert(:channel)
  end

  test "stream factory works" do
    assert %Glimesh.Streams.Stream{} = insert(:stream)
  end

  test "category factory works" do
    assert %Glimesh.Streams.Category{} = insert(:category)
  end

  test "subcategory factory works" do
    assert %Glimesh.Streams.Subcategory{} = insert(:subcategory)
  end

  test "tag factory works" do
    assert %Glimesh.Streams.Tag{} = insert(:tag)
  end

  test "follower factory works" do
    assert %Glimesh.AccountFollows.Follower{} = insert(:follower)
  end
end
