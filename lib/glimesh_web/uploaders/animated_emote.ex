defmodule Glimesh.Uploaders.AnimatedEmote do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:gif]

  def acl(:gif, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    Glimesh.FileValidation.validate(file, [:gif])
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
