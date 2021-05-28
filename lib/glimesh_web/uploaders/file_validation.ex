defmodule Glimesh.FileValidation do
  @moduledoc """
  Reads a file and matches against common magic bytes to determine the type of the file
  """
  require Logger

  import SweetXml

  @doc """
  Helper function to quickly match against known types.

  ## Examples

      iex> validate(png_file, [:png, :jpg])
      true

      iex> validate(svg_file, [:png])
      false

  """
  def validate(%Waffle.File{path: path}, allowed \\ []) do
    case get_file_type(path) do
      {:ok, type} ->
        type in allowed

      _ ->
        false
    end
  end

  @doc """
  Dumb check for file extensions.

  Should not be used as files (especially temporary) may not contain extensions.
  """
  def validate_extension(%Waffle.File{file_name: file_name}, allowed \\ []) do
    Enum.member?(allowed, file_name |> Path.extname() |> String.downcase())
  end

  @doc """
  Validate that the file is an SVG as best as we can.

  SVG's are XML files, and they should contain an svg element with a svg namespace.

  https://www.w3.org/TR/SVG2/struct.html#Namespace states that only one svg
  namespace exists, so we check for that using an XML parser.
  """
  def validate_svg(%Waffle.File{path: path}) do
    data = File.read!(path)

    xml = SweetXml.parse(data)

    case SweetXml.xpath(xml, ~x"/*/namespace::*[name()='']") do
      {:xmlNsNode, _, _, _, :"http://www.w3.org/2000/svg"} ->
        true

      _ ->
        Logger.info("Unexpected SVG namespace contents")
        false
    end
  end

  @doc """
  Matches a file against known magic bytes.
  """
  def get_file_type(path) when is_binary(path) do
    case File.read(path) do
      {:ok, <<255, 216, 255, _rest::binary>>} ->
        # FF D8 FF
        {:ok, :jpg}

      {:ok, <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>} ->
        # 89 50 4E 47 0D 0A 1A 0A
        {:ok, :png}

      {:ok, <<71, 73, 70, 56, 55, 97, _rest::binary>>} ->
        # 47 49 46 38 37 61
        {:ok, :gif}

      {:ok, <<71, 73, 70, 56, 57, 97, _rest::binary>>} ->
        # 47 49 46 38 39 61
        {:ok, :gif}

      {:ok, _} ->
        {:ok, :unknown}

      {:error, reason} ->
        {:error, List.to_string(:file.format_error(reason))}
    end
  end
end
