defmodule Glimesh.StreamThumbnail do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original]

  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    Glimesh.FileValidation.validate(file, [:png, :jpg])
  end

  # Define a thumbnail transformation:
  def transform(:original, _) do
    {:convert,
     "-strip -thumbnail 832x468^ -gravity center -extent 832x468 -quality 85% -format jpg", :jpg}
  end

  # Override the persisted filenames:
  def filename(_version, {_file, %Glimesh.Streams.Stream{} = stream}) do
    stream.id
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/stream-thumbnails"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [
      cache_control: "public, max-age=604800",
      content_type: MIME.from_path(file.file_name)
    ]
  end

  # Provide a default URL if there hasn't been a file uploaded
  if Mix.env() == :dev do
    def default_url(_version, _scope) do
      Enum.random(Application.get_env(:glimesh, :random_thumbnails))
    end
  else
    def default_url(_version, _scope) do
      fallback_url()
    end
  end

  defp fallback_url do
    GlimeshWeb.Router.Helpers.static_url(
      GlimeshWeb.Endpoint,
      "/images/stream-not-started.jpg"
    )
  end
end
