defmodule Glimesh.Interactive do
  @moduledoc """
  Handles all interactive file uploads
  """
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @max_file_size 10_000_000
  @allowed_files [
    "htm",
    "html",
    "asp",
    "cshtml",
    "js",
    "css",
    "gif",
    "png",
    "jpg",
    "mp4",
    "mov",
    "avi",
    "mkv",
    "webm",
    "mp3",
    "opus",
    "ogg",
    "wem",
    "flac",
    "wav",
    "json",
    "csv"
  ]

  @versions [:original]

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Validate interactive projects.
  def validate({%Waffle.File{} = file, _channel}) do
    # check file size
    with true <- file_size(file) <= @max_file_size,
         {:ext_check, true} <-
           {:ext_check, String.ends_with?(to_string(file.file_name), @allowed_files)} do
      :ok
    else
      {:ext_check, _} -> {:error, "Your project included an unsupported file."}
      _ -> {:error, "An unknown error has occured"}
    end
  end

  # Do nothing
  def transform(:original, _request) do
    :noaction
  end

  # Override the uploaded filenames.
  def filename(:original, {file, %Glimesh.Streams.Channel{} = _channel}) do
    # UserFolderSelected/filename.extension
    # remove the initial folder in the file name UserFolderSelected
    name = String.replace(file.file_name, ~r/^.+?(?=\/)/, "", global: false)
    # remove the leading slash /
    name = String.slice(name, 1, String.length(name))
    # Remove the file extension since ecto will add that.
    String.replace(name, ~r/\.[^.]*$/, "")
  end

  # override the requested filenames
  def filename(_version, {file, _channel}) do
    # remove extension
    String.replace(file.file_name, ~r/\.[^.]*$/, "")
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "uploads/interactive/#{scope.id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  def file_size(%Waffle.File{} = file) do
    File.stat!(file.path) |> Map.get(:size)
  end

  def default_url(_version, _scope) do
    nil
  end
end
