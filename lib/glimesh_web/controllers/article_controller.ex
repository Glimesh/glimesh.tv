defmodule GlimeshWeb.ArticleController do
  use GlimeshWeb, :controller

  alias Glimesh.Blog
  alias Glimesh.Blog.Article

  # General Routes
  def index(conn, _params) do
    articles = Blog.list_articles()
    render(conn, "index.html", articles: articles)
  end

  def show(conn, %{"slug" => slug}) do
    article = Blog.get_article_by_slug!(slug)

    render(conn, "show.html",
      article: article,
      page_title: article.title,
      page_description: article.description
    )
  end

  # Admin Only
  def new(conn, _params) do
    changeset = Blog.change_article(%Article{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"article" => article_params}) do
    user = conn.assigns.current_user

    case Blog.create_article(user, article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article created successfully.")
        |> redirect(to: Routes.article_path(conn, :show, article.slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    article = Blog.get_article_by_slug!(slug)
    changeset = Blog.change_article(article)
    render(conn, "edit.html", article: article, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "article" => article_params}) do
    user = conn.assigns.current_user
    article = Blog.get_article_by_slug!(slug)

    case Blog.update_article(article, article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article updated successfully.")
        |> redirect(to: Routes.article_path(conn, :show, article.slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", article: article, changeset: changeset)
    end
  end
end
