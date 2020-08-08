defmodule GlimeshWeb.ArticleControllerTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Blog
  import Glimesh.AccountsFixtures

  @create_attrs %{
    body_md: "some body_md",
    description: "some description",
    published: true,
    slug: "some-slug",
    title: "some title"
  }
  @update_attrs %{
    body_md: "some updated body_md",
    description: "some updated description",
    published: false,
    slug: "some-updated-slug",
    title: "some updated title"
  }
  @invalid_attrs %{
    body_html: nil,
    body_md: nil,
    description: nil,
    published: nil,
    slug: nil,
    title: nil
  }

  def fixture(:article) do
    {:ok, article} = Blog.create_article(admin_fixture(), @create_attrs)
    article
  end

  describe "index" do
    test "lists all articles", %{conn: conn} do
      conn = get(conn, Routes.article_path(conn, :index))
      assert html_response(conn, 200) =~ "Glimesh Blog"
    end
  end

  describe "new article" do
    setup :register_and_log_in_admin_user

    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.article_path(conn, :new))
      assert html_response(conn, 200) =~ "New Article"
    end
  end

  describe "create article" do
    setup :register_and_log_in_admin_user

    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.article_path(conn, :create), article: @create_attrs)

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == Routes.article_path(conn, :show, slug)

      conn = get(conn, Routes.article_path(conn, :show, slug))
      assert html_response(conn, 200) =~ "some title"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.article_path(conn, :create), article: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Article"
    end
  end

  describe "edit article" do
    setup [:register_and_log_in_admin_user, :create_article]

    test "renders form for editing chosen article", %{conn: conn, article: article} do
      conn = get(conn, Routes.article_path(conn, :edit, article.slug))
      assert html_response(conn, 200) =~ "Edit Article"
    end
  end

  describe "update article" do
    setup [:register_and_log_in_admin_user, :create_article]

    test "redirects when data is valid", %{conn: conn, article: article} do
      conn = put(conn, Routes.article_path(conn, :update, article.slug), article: @update_attrs)
      assert redirected_to(conn) == Routes.article_path(conn, :show, @update_attrs.slug)

      conn = get(conn, Routes.article_path(conn, :show, @update_attrs.slug))
      assert html_response(conn, 200) =~ "<p>\nsome updated body_md</p>\n"
    end

    test "renders errors when data is invalid", %{conn: conn, article: article} do
      conn = put(conn, Routes.article_path(conn, :update, article.slug), article: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Article"
    end
  end

  defp create_article(_) do
    article = fixture(:article)
    %{article: article}
  end
end
