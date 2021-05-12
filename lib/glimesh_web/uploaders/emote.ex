defmodule Glimesh.Uploaders.Emote do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:svg, :png]

  def acl(:svg, _), do: :public_read
  def acl(:png, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    Glimesh.FileValidation.validate_extension(file, ~w(.svg))
  end

  def transform(:svg, _) do
    # svgo -f input.svg -o output.svg
    {"svgo",
     fn input, output ->
       " -f #{input} -o #{output}"
     end}
  end

  def transform(:png, _) do
    # rsvg-convert -w 256 -h 256 input.svg > output.png
    {"rsvg-convert",
     fn input, output ->
       " -w 256 -h 256 #{input} > #{output}"
     end, "png"}
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
