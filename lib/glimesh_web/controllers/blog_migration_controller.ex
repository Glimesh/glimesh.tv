defmodule GlimeshWeb.BlogMigrationController do
  use GlimeshWeb, :controller

  def redirect_blog(conn, _params) do
    conn |> redirect(external: "https://blog.glimesh.tv/")
  end

  # General Routes
  def redirect_post(conn, %{"slug" => slug}) do
    if Glimesh.BlogMigration.should_redirect(slug) do
      conn |> redirect(external: "https://blog.glimesh.tv/posts/#{slug}")
    else
      conn |> redirect(to: "/")
    end
  end
end
