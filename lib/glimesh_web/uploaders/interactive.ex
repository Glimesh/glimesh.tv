defmodule Glimesh.Interactive do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @max_file_size 10_000_000

  @versions [:original]

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Validate interactive projects.
  def validate({%Waffle.File{} = file, _}) do
    with true <- file_size(file) <= @max_file_size, # check file size
      true <- ".zip" == file.file_name |> Path.extname() |> String.downcase(), # must be .zip file
      {:ok, files} <- :zip.list_dir(String.to_charlist(file.path)), # get files in zip
      true <- Enum.any?(files, fn e -> elem(e, 1) == 'index.html' end) do # find index.html in folder
        IO.puts("All passed!")

        :ok
      else
        false ->
          IO.puts("bad error, oh no")
          {:error, "Upload must be a zip folder with an index.html file located within"}
        _ ->
          {:error, "Upload Error. See formats"}
      end
    :ok
  end

  # Converts the .zip to a normal folder
   def transform(:original, request) do
    # get the ID from the channel
    id = elem(request, 1).id
    # unzip the folder to the uploads dir
    :zip.unzip(String.to_charlist(elem(request, 0).path), [{:cwd, String.to_charlist("uploads/interactive/#{id}")}])
    # Since we just converted it the waffle lib doesn't have to do anything
    # Technically, this is an invalid return but it prevents our created file from being deleted.
    # Waffle isn't meant to handle folders and this is the only way I found to solve that
    {:noaction}
   end

  # Override the persisted filenames:
  def filename(_version, {_file, %Glimesh.Streams.Channel{} = channel}) do
    channel.id
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, _scope}) do
    "uploads/interactive"
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end

  def file_size(%Waffle.File{} = file) do
    File.stat!(file.path) |> Map.get(:size)
  end

  # Remove projects that are zip files
  def cleanup() do
    files = File.ls("uploads/interactive")
    elem(files, 1) |> Enum.each(fn file ->
      case String.ends_with?(file, ".zip") do
        true -> File.rm_rf("uploads/interactive/#{file}")
        false -> nil
      end
    end)
  end
end
