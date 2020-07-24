defmodule Glimesh.PaymentsTest do
  use Glimesh.DataCase

  alias Glimesh.Payments

  describe "platform_subscriptions" do
    alias Glimesh.Payments.PlatformSubscription

    @valid_attrs %{ended_at: "some ended_at", started_at: "some started_at", stripe_product_id: "some stripe_product_id"}
    @update_attrs %{ended_at: "some updated ended_at", started_at: "some updated started_at", stripe_product_id: "some updated stripe_product_id"}
    @invalid_attrs %{ended_at: nil, started_at: nil, stripe_product_id: nil}

    def platform_subscription_fixture(attrs \\ %{}) do
      {:ok, platform_subscription} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_platform_subscription()

      platform_subscription
    end

    test "list_platform_subscriptions/0 returns all platform_subscriptions" do
      platform_subscription = platform_subscription_fixture()
      assert Payments.list_platform_subscriptions() == [platform_subscription]
    end

    test "get_platform_subscription!/1 returns the platform_subscription with given id" do
      platform_subscription = platform_subscription_fixture()
      assert Payments.get_platform_subscription!(platform_subscription.id) == platform_subscription
    end

    test "create_platform_subscription/1 with valid data creates a platform_subscription" do
      assert {:ok, %PlatformSubscription{} = platform_subscription} = Payments.create_platform_subscription(@valid_attrs)
      assert platform_subscription.ended_at == "some ended_at"
      assert platform_subscription.started_at == "some started_at"
      assert platform_subscription.stripe_product_id == "some stripe_product_id"
    end

    test "create_platform_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_platform_subscription(@invalid_attrs)
    end

    test "update_platform_subscription/2 with valid data updates the platform_subscription" do
      platform_subscription = platform_subscription_fixture()
      assert {:ok, %PlatformSubscription{} = platform_subscription} = Payments.update_platform_subscription(platform_subscription, @update_attrs)
      assert platform_subscription.ended_at == "some updated ended_at"
      assert platform_subscription.started_at == "some updated started_at"
      assert platform_subscription.stripe_product_id == "some updated stripe_product_id"
    end

    test "update_platform_subscription/2 with invalid data returns error changeset" do
      platform_subscription = platform_subscription_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_platform_subscription(platform_subscription, @invalid_attrs)
      assert platform_subscription == Payments.get_platform_subscription!(platform_subscription.id)
    end

    test "delete_platform_subscription/1 deletes the platform_subscription" do
      platform_subscription = platform_subscription_fixture()
      assert {:ok, %PlatformSubscription{}} = Payments.delete_platform_subscription(platform_subscription)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_platform_subscription!(platform_subscription.id) end
    end

    test "change_platform_subscription/1 returns a platform_subscription changeset" do
      platform_subscription = platform_subscription_fixture()
      assert %Ecto.Changeset{} = Payments.change_platform_subscription(platform_subscription)
    end
  end

  describe "platform_subscriptions" do
    alias Glimesh.Payments.PlatformSubscriptions

    @valid_attrs %{ended_at: "some ended_at", started_at: "some started_at", stripe_product_id: 42}
    @update_attrs %{ended_at: "some updated ended_at", started_at: "some updated started_at", stripe_product_id: 43}
    @invalid_attrs %{ended_at: nil, started_at: nil, stripe_product_id: nil}

    def platform_subscriptions_fixture(attrs \\ %{}) do
      {:ok, platform_subscriptions} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_platform_subscriptions()

      platform_subscriptions
    end

    test "list_platform_subscriptions/0 returns all platform_subscriptions" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert Payments.list_platform_subscriptions() == [platform_subscriptions]
    end

    test "get_platform_subscriptions!/1 returns the platform_subscriptions with given id" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert Payments.get_platform_subscriptions!(platform_subscriptions.id) == platform_subscriptions
    end

    test "create_platform_subscriptions/1 with valid data creates a platform_subscriptions" do
      assert {:ok, %PlatformSubscriptions{} = platform_subscriptions} = Payments.create_platform_subscriptions(@valid_attrs)
      assert platform_subscriptions.ended_at == "some ended_at"
      assert platform_subscriptions.started_at == "some started_at"
      assert platform_subscriptions.stripe_product_id == 42
    end

    test "create_platform_subscriptions/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_platform_subscriptions(@invalid_attrs)
    end

    test "update_platform_subscriptions/2 with valid data updates the platform_subscriptions" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert {:ok, %PlatformSubscriptions{} = platform_subscriptions} = Payments.update_platform_subscriptions(platform_subscriptions, @update_attrs)
      assert platform_subscriptions.ended_at == "some updated ended_at"
      assert platform_subscriptions.started_at == "some updated started_at"
      assert platform_subscriptions.stripe_product_id == 43
    end

    test "update_platform_subscriptions/2 with invalid data returns error changeset" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_platform_subscriptions(platform_subscriptions, @invalid_attrs)
      assert platform_subscriptions == Payments.get_platform_subscriptions!(platform_subscriptions.id)
    end

    test "delete_platform_subscriptions/1 deletes the platform_subscriptions" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert {:ok, %PlatformSubscriptions{}} = Payments.delete_platform_subscriptions(platform_subscriptions)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_platform_subscriptions!(platform_subscriptions.id) end
    end

    test "change_platform_subscriptions/1 returns a platform_subscriptions changeset" do
      platform_subscriptions = platform_subscriptions_fixture()
      assert %Ecto.Changeset{} = Payments.change_platform_subscriptions(platform_subscriptions)
    end
  end
end
