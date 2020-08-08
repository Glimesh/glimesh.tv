defmodule Glimesh.Avatar do
  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  use Waffle.Ecto.Definition

  @versions [:original]

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:original, _) do
    {:convert, "-strip -thumbnail 200x200^ -gravity center -extent 200x200 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    scope.username
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/avatars"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/200x200.jpg"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
