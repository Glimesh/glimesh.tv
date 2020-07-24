defmodule GlimeshWeb.PlatformSubscriptionLiveTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Glimesh.Payments

  @create_attrs %{ended_at: "some ended_at", started_at: "some started_at", stripe_product_id: "some stripe_product_id"}
  @update_attrs %{ended_at: "some updated ended_at", started_at: "some updated started_at", stripe_product_id: "some updated stripe_product_id"}
  @invalid_attrs %{ended_at: nil, started_at: nil, stripe_product_id: nil}

  defp fixture(:platform_subscription) do
    {:ok, platform_subscription} = Payments.create_platform_subscription(@create_attrs)
    platform_subscription
  end

  defp create_platform_subscription(_) do
    platform_subscription = fixture(:platform_subscription)
    %{platform_subscription: platform_subscription}
  end

  describe "Index" do
    setup [:create_platform_subscription]

    test "lists all platform_subscriptions", %{conn: conn, platform_subscription: platform_subscription} do
      {:ok, _index_live, html} = live(conn, Routes.platform_subscription_index_path(conn, :index))

      assert html =~ "Listing Platform subscriptions"
      assert html =~ platform_subscription.ended_at
    end

    test "saves new platform_subscription", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.platform_subscription_index_path(conn, :index))

      assert index_live |> element("a", "New Platform subscription") |> render_click() =~
               "New Platform subscription"

      assert_patch(index_live, Routes.platform_subscription_index_path(conn, :new))

      assert index_live
             |> form("#platform_subscription-form", platform_subscription: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#platform_subscription-form", platform_subscription: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.platform_subscription_index_path(conn, :index))

      assert html =~ "Platform subscription created successfully"
      assert html =~ "some ended_at"
    end

    test "updates platform_subscription in listing", %{conn: conn, platform_subscription: platform_subscription} do
      {:ok, index_live, _html} = live(conn, Routes.platform_subscription_index_path(conn, :index))

      assert index_live |> element("#platform_subscription-#{platform_subscription.id} a", "Edit") |> render_click() =~
               "Edit Platform subscription"

      assert_patch(index_live, Routes.platform_subscription_index_path(conn, :edit, platform_subscription))

      assert index_live
             |> form("#platform_subscription-form", platform_subscription: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#platform_subscription-form", platform_subscription: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.platform_subscription_index_path(conn, :index))

      assert html =~ "Platform subscription updated successfully"
      assert html =~ "some updated ended_at"
    end

    test "deletes platform_subscription in listing", %{conn: conn, platform_subscription: platform_subscription} do
      {:ok, index_live, _html} = live(conn, Routes.platform_subscription_index_path(conn, :index))

      assert index_live |> element("#platform_subscription-#{platform_subscription.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#platform_subscription-#{platform_subscription.id}")
    end
  end

  describe "Show" do
    setup [:create_platform_subscription]

    test "displays platform_subscription", %{conn: conn, platform_subscription: platform_subscription} do
      {:ok, _show_live, html} = live(conn, Routes.platform_subscription_show_path(conn, :show, platform_subscription))

      assert html =~ "Show Platform subscription"
      assert html =~ platform_subscription.ended_at
    end

    test "updates platform_subscription within modal", %{conn: conn, platform_subscription: platform_subscription} do
      {:ok, show_live, _html} = live(conn, Routes.platform_subscription_show_path(conn, :show, platform_subscription))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Platform subscription"

      assert_patch(show_live, Routes.platform_subscription_show_path(conn, :edit, platform_subscription))

      assert show_live
             |> form("#platform_subscription-form", platform_subscription: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#platform_subscription-form", platform_subscription: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.platform_subscription_show_path(conn, :show, platform_subscription))

      assert html =~ "Platform subscription updated successfully"
      assert html =~ "some updated ended_at"
    end
  end
end
