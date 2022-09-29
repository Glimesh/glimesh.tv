defmodule Glimesh.Interactive do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @max_file_size 10_000_000
  @allowed_files [
    "htm", "html", "asp", "cshtml", "js", "css", "gif", "png", "jpg",
    "mp4", "mov", "avi", "mkv", "webm", "mp3", "opus", "ogg", "wem", "flac", "wav",
    "json", "csv"
  ]

  @versions [:original]

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Validate interactive projects.
  def validate({%Waffle.File{} = file, channel}) do
    with true <- file_size(file) <= @max_file_size, # check file size
      {:zip_check, true} <- {:zip_check, ".zip" == file.file_name |> Path.extname() |> String.downcase()}, # must be .zip file
      {:ok, files} <- :zip.list_dir(String.to_charlist(file.path)), # get files in zip. DOES NOT STORE THEM
      {:html_check, true} <- {:html_check, Enum.any?(files, fn e -> elem(e, 1) == 'index.html' end)}, # find index.html in folder
      {:ext_check, true} <- {:ext_check, Enum.all?(files, fn e -> # For each file...
        case e do
          # Check the filename is in the allow list
          {:zip_file, file_name, _, _, _, _} -> String.ends_with?(to_string(file_name), @allowed_files)
          # Zip comment, can be ignored
          _ -> true
        end
        end)} do
        IO.puts("All Interactive files are valid!")
        # If a user uploaded a previous project it needs to be deleted.
        remove_old_project(channel.id)
        :ok
      else
        {:zip_check, _} -> {:error, "Interactive projects must be a .zip file"}
        {:html_check, _} -> {:error, "Interactive projects must contain a top level index.html file"}
        {:ext_check, _} -> {:error, "Your project included an unsupported file."}
        _ -> {:error, "An unknown error has occured"}
      end
  end

  # Converts the .zip to a normal folder
   def transform(:original, request) do
    # get the ID from the channel
    id = elem(request, 1).id
    # unzip the folder to the uploads dir. Use the ID in the path
    :zip.unzip(String.to_charlist(elem(request, 0).path), [{:cwd, String.to_charlist("uploads/interactive/#{id}")}])
    # Since we just extracted it the waffle lib doesn't have to do transform anything
    # Technically, this is an invalid return value but it prevents our created file from being deleted.
    # I'm really not sure how that works. But it does. C o o l
    # A proper return is :noaction without the {}
    {:noaction}
   end

  # Override the persisted filenames. This is for the zip file
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

  # Remove all of the zip files. See interactive_pruner_cron.ex
  # Once a project is uploaded and extracted the zip file is no longer needed.
  # When we get this to a CDN we probably won't need this.
  def cleanup() do
    files = File.ls("uploads/interactive")
    elem(files, 1) |> Enum.each(fn file ->
      case String.ends_with?(file, ".zip") do
        true -> File.rm_rf("uploads/interactive/#{file}")
        false -> nil
      end
    end)
  end

  # Cleans out the current project for a channel. This removes the extracted files, not the zip
  def remove_old_project(id) do
    case File.dir?("uploads/interactive/#{id}") do
      true -> File.rm_rf("uploads/interactive/#{id}")
      false -> :error
    end
  end
end
