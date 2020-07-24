defmodule GlimeshWeb.PlatformSubscriptionsControllerTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Payments

  @create_attrs %{ended_at: "some ended_at", started_at: "some started_at", stripe_product_id: 42}
  @update_attrs %{ended_at: "some updated ended_at", started_at: "some updated started_at", stripe_product_id: 43}
  @invalid_attrs %{ended_at: nil, started_at: nil, stripe_product_id: nil}

  def fixture(:platform_subscriptions) do
    {:ok, platform_subscriptions} = Payments.create_platform_subscriptions(@create_attrs)
    platform_subscriptions
  end

  describe "index" do
    test "lists all platform_subscriptions", %{conn: conn} do
      conn = get(conn, Routes.platform_subscriptions_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Platform subscriptions"
    end
  end

  describe "new platform_subscriptions" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.platform_subscriptions_path(conn, :new))
      assert html_response(conn, 200) =~ "New Platform subscriptions"
    end
  end

  describe "create platform_subscriptions" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.platform_subscriptions_path(conn, :create), platform_subscriptions: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.platform_subscriptions_path(conn, :show, id)

      conn = get(conn, Routes.platform_subscriptions_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Platform subscriptions"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.platform_subscriptions_path(conn, :create), platform_subscriptions: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Platform subscriptions"
    end
  end

  describe "edit platform_subscriptions" do
    setup [:create_platform_subscriptions]

    test "renders form for editing chosen platform_subscriptions", %{conn: conn, platform_subscriptions: platform_subscriptions} do
      conn = get(conn, Routes.platform_subscriptions_path(conn, :edit, platform_subscriptions))
      assert html_response(conn, 200) =~ "Edit Platform subscriptions"
    end
  end

  describe "update platform_subscriptions" do
    setup [:create_platform_subscriptions]

    test "redirects when data is valid", %{conn: conn, platform_subscriptions: platform_subscriptions} do
      conn = put(conn, Routes.platform_subscriptions_path(conn, :update, platform_subscriptions), platform_subscriptions: @update_attrs)
      assert redirected_to(conn) == Routes.platform_subscriptions_path(conn, :show, platform_subscriptions)

      conn = get(conn, Routes.platform_subscriptions_path(conn, :show, platform_subscriptions))
      assert html_response(conn, 200) =~ "some updated ended_at"
    end

    test "renders errors when data is invalid", %{conn: conn, platform_subscriptions: platform_subscriptions} do
      conn = put(conn, Routes.platform_subscriptions_path(conn, :update, platform_subscriptions), platform_subscriptions: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Platform subscriptions"
    end
  end

  describe "delete platform_subscriptions" do
    setup [:create_platform_subscriptions]

    test "deletes chosen platform_subscriptions", %{conn: conn, platform_subscriptions: platform_subscriptions} do
      conn = delete(conn, Routes.platform_subscriptions_path(conn, :delete, platform_subscriptions))
      assert redirected_to(conn) == Routes.platform_subscriptions_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.platform_subscriptions_path(conn, :show, platform_subscriptions))
      end
    end
  end

  defp create_platform_subscriptions(_) do
    platform_subscriptions = fixture(:platform_subscriptions)
    %{platform_subscriptions: platform_subscriptions}
  end
end
