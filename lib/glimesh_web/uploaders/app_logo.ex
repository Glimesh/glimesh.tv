defmodule Glimesh.AppLogo do
  @moduledoc false

  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  use Waffle.Ecto.Definition

  @versions [:original]

  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    Glimesh.FileValidation.validate(file, [:png, :jpg])
  end

  # Define a thumbnail transformation:
  def transform(:original, _) do
    {:convert, "-strip -thumbnail 200x200^ -gravity center -extent 200x200 -format png", :png}
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/applications"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [
      cache_control: "public, max-age=604800",
      content_type: MIME.from_path(file.file_name)
    ]
  end

  # # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/200x200.jpg"
  end
end
