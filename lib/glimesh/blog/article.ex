defmodule Glimesh.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    belongs_to :author, Glimesh.Accounts.User

    field :body_html, :string
    field :body_md, :string
    field :description, :string
    field :published, :boolean, default: false
    field :slug, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :slug, :body_md, :description, :published])
    |> validate_required([:title, :slug, :body_md, :description, :published])
    |> set_body_html()
    |> unique_constraint(:slug)
  end

  def set_body_html(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{body_md: body_md}} ->
        {:ok, html_doc, []} = Earmark.as_html(body_md)
        put_change(changeset, :body_html, html_doc)
      _ ->
        changeset
    end
  end
end
