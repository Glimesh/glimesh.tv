defmodule Glimesh.ChatBackground do
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
    {:convert, "-strip -thumbnail 300x300^ -gravity center -extent 300x300 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(_version, {_file, %Glimesh.Streams.Channel{} = channel}) do
    channel.id
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/chat-backgrounds"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "/images/bg.png"
  end
end
