defmodule Glimesh.BlogTest do
  use Glimesh.DataCase

  alias Glimesh.Blog
  import Glimesh.AccountsFixtures

  describe "articles" do
    alias Glimesh.Blog.Article

    @valid_attrs %{body_md: "some body_md", description: "some description", published: true, slug: "some slug", title: "some title"}
    @update_attrs %{body_md: "some updated body_md", description: "some updated description", published: false, slug: "some updated slug", title: "some updated title"}
    @invalid_attrs %{body_html: nil, body_md: nil, description: nil, published: nil, slug: nil, title: nil}

    def article_fixture(attrs \\ %{}) do
      {:ok, article} = Blog.create_article(admin_fixture(), attrs |> Enum.into(@valid_attrs))
      article
    end

    test "list_articles/0 returns all articles" do
      article = article_fixture()
      assert Enum.map(Blog.list_articles(), fn x -> x.title end) == [article.title]
    end

    test "get_article!/1 returns the article with given id" do
      article = article_fixture()
      assert Blog.get_article!(article.id).title == article.title
    end

    test "get_article!/1 returns the article with given slug" do
      article = article_fixture()
      assert Blog.get_article_by_slug!(article.slug).title == article.title
    end

    test "create_article/1 with valid data creates a article" do
      assert {:ok, %Article{} = article} = Blog.create_article(admin_fixture(), @valid_attrs)
      assert article.body_html == "<p>\nsome body_md</p>\n"
      assert article.body_md == "some body_md"
      assert article.description == "some description"
      assert article.published == true
      assert article.slug == "some slug"
      assert article.title == "some title"
    end

    test "create_article/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_article(admin_fixture(), @invalid_attrs)
    end

    test "create_article/1 with no user returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_article(nil, @invalid_attrs)
    end

    test "update_article/2 with valid data updates the article" do
      article = article_fixture()
      assert {:ok, %Article{} = article} = Blog.update_article(article, @update_attrs)
      assert article.body_html == "<p>\nsome updated body_md</p>\n"
      assert article.body_md == "some updated body_md"
      assert article.description == "some updated description"
      assert article.published == false
      assert article.slug == "some updated slug"
      assert article.title == "some updated title"
    end

    test "update_article/2 with invalid data returns error changeset" do
      article = article_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.update_article(article, @invalid_attrs)
      assert article.title == Blog.get_article!(article.id).title
    end

    test "change_article/1 returns a article changeset" do
      article = article_fixture()
      assert %Ecto.Changeset{} = Blog.change_article(article)
    end
  end
end
