defmodule Glimesh.CategoryAvatar do
  @moduledoc false

  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  use Waffle.Ecto.Definition

  # To add a thumbnail version:
  @versions [:portrait, :landscape]

  def acl(:portrait, _), do: :public_read
  def acl(:landscape, _), do: :public_read

  def validate({file, _}) do
    ~w(.jpg .jpeg .png) |> Enum.member?(Path.extname(file.file_name))
  end

  def transform(:portrait, _) do
    {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  end

  def transform(:landscape, _) do
    {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  end

  def default_url(:portrait, _scope) do
    "/images/200x200.jpg"
  end

  def default_url(:landscape, _scope) do
    "/images/200x200.jpg"
  end
end
