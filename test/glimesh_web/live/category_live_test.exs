defmodule GlimeshWeb.CategoryLiveTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Glimesh.Streams

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  defp fixture(:category, parent_category) do
    {:ok, category} =
      Streams.create_category(@create_attrs |> Enum.into(%{parent_id: parent_category.id}))

    category
  end

  defp fixture(:parent_category) do
    {:ok, category} =
      Streams.create_category(%{
        name: "some parent",
        parent_id: nil
      })

    category
  end

  defp create_category(_) do
    parent_category = fixture(:parent_category)
    category = fixture(:category, parent_category)
    %{parent_category: parent_category, category: category}
  end

  describe "Category Normal User Functionality" do
    test "lists all categories", %{conn: conn} do
      {:error, {:redirect, param}} = live(conn, Routes.category_index_path(conn, :index))

      assert param.to =~ "/users/log_in"
    end
  end

  describe "Category Admin Functionality" do
    setup [:register_and_log_in_admin_user, :create_category]

    test "lists all categories", %{conn: conn, category: category} do
      {:ok, _index_live, html} = live(conn, Routes.category_index_path(conn, :index))

      assert html =~ "Listing Categories"
      assert html =~ category.name
    end

    test "saves new category", %{conn: conn, parent_category: parent_category} do
      {:ok, index_live, _html} = live(conn, Routes.category_index_path(conn, :index))

      assert index_live |> element("a", "New Category") |> render_click() =~
               "New Category"

      assert_patch(index_live, Routes.category_index_path(conn, :new))

      assert index_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      new_input = %{name: "some new category", parent_id: parent_category.id}

      {:ok, _, html} =
        index_live
        |> form("#category-form", category: new_input)
        |> render_submit()
        |> follow_redirect(conn, Routes.category_index_path(conn, :index))

      assert html =~ "Category created successfully"
      assert html =~ "some new category"
    end

    test "updates category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, Routes.category_index_path(conn, :index))

      assert index_live |> element("#category-#{category.id} a", "Edit") |> render_click() =~
               "Edit Category"

      assert_patch(index_live, Routes.category_index_path(conn, :edit, category))

      assert index_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#category-form", category: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.category_index_path(conn, :index))

      assert html =~ "Category updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, Routes.category_index_path(conn, :index))

      assert index_live |> element("#category-#{category.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#category-#{category.id}")
    end

    test "displays category", %{conn: conn, category: category} do
      {:ok, _show_live, html} = live(conn, Routes.category_show_path(conn, :show, category))

      assert html =~ "Show Category"
      assert html =~ category.name
    end

    test "updates category within modal", %{conn: conn, category: category} do
      {:ok, show_live, _html} = live(conn, Routes.category_show_path(conn, :show, category))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Category"

      assert_patch(show_live, Routes.category_show_path(conn, :edit, category))

      assert show_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#category-form", category: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.category_show_path(conn, :show, category))

      assert html =~ "Category updated successfully"
      assert html =~ "some updated name"
    end
  end
end
