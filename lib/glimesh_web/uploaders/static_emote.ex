defmodule Glimesh.Uploaders.StaticEmote do
  @moduledoc """
  Security resources for SVG images:
  https://svg.digi.ninja/svg

  Direct view - vulnerable - The file is linked to directly.
  Direct view with content-disposition: attachment - not vulnerable - Headers are sent to force the file to be downloaded.
  Direct view with CSP - not vulnerable - The Content Security Policy is set to disallow inline JavaScript.
  Image Tags - not vulnerable - The SVG is referenced through image tags which prevent scripts.
  Image Tags With CSP - not vulnerable - Image tags and the same CSP as above for double protection.

  Since we cannot manually set CSP headers with most CDNs, we're utilizing both sanitizing the image with svgo, serving it through an img tag so js cannot run, and setting the content-disposition to attachment so the browser wont automatically run it.
  """

  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:svg, :png]

  def acl(:svg, _), do: :public_read
  def acl(:png, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    Glimesh.FileValidation.validate_svg(file)
  end

  def transform(:svg, _) do
    # svgo -f input.svg -o output.svg
    config_path = Path.join([:code.priv_dir(:glimesh), "svgo.config.js"])

    {"svgo",
     fn input, output ->
       " #{input} -o #{output} --config #{config_path}"
     end, "svg"}
  end

  def transform(:png, _) do
    # rsvg-convert -w 256 -h 256 input.svg > output.png
    {"rsvg-convert",
     fn input, output ->
       " -w 256 -h 256 #{input} -o #{output}"
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
      content_disposition: "attachment",
      cache_control: "public, max-age=604800",
      content_type: MIME.from_path(file.file_name)
    ]
  end
end
