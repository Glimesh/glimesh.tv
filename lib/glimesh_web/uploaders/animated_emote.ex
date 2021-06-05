defmodule Glimesh.Uploaders.AnimatedEmote do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  alias Glimesh.FileValidation

  @versions [:gif]
  @max_size 1_000_000

  @spec acl(any, any) :: :private | :public_read
  def acl(:gif, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    FileValidation.validate_size(file, @max_size) and
      FileValidation.validate(file, [:gif]) and
      FileValidation.validate_image(file,
        shape: :square,
        min_width: 128,
        min_height: 128,
        max_width: 256,
        max_height: 256
      )
  end

  # Override the persisted filenames:
  def filename(_version, {_file, %Glimesh.Emotes.Emote{emote: emote_name}}) do
    emote_name
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/emotes"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [
      cache_control: "public, max-age=604800",
      content_type: MIME.from_path(file.file_name)
    ]
  end
end
