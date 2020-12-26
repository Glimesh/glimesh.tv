defmodule Glimesh.StreamThumbnail do
  @moduledoc false

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original]

  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .png) |> Enum.member?(Path.extname(file.file_name))
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

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/stream-not-started.jpg"
  end
end
