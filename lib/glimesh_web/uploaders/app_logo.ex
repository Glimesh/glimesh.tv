defmodule Glimesh.AppLogo do
  @moduledoc false

  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  use Waffle.Ecto.Definition

  @versions [:original]

  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:original, _) do
    {:convert, "-strip -thumbnail 200x200^ -gravity center -extent 200x200 -format png", :png}
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/applications"
  end

  # # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/200x200.jpg"
  end
end
