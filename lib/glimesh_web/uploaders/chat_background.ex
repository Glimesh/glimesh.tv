defmodule Glimesh.ChatBackground do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original]
  @max_file_size 100_000

  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    type_passes = Glimesh.FileValidation.validate(file, [:png, :jpg])

    size_passes = file_size(file) <= @max_file_size

    type_passes && size_passes
  end

  # Define a thumbnail transformation:
  def transform(:original, _) do
    {:convert, "-strip -format png", :png}
  end

  # Override the persisted filenames:
  def filename(_version, {_file, %Glimesh.Streams.Channel{} = channel}) do
    channel.id
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/chat-backgrounds"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [
      cache_control: "public, max-age=604800",
      content_type: MIME.from_path(file.file_name)
    ]
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/bg.png"
  end

  defp file_size(%Waffle.File{} = file) do
    File.stat!(file.path) |> Map.get(:size)
  end
end
