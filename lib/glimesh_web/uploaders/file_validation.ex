defmodule Glimesh.FileValidation do
  @moduledoc """
  Reads a file and matches against common magic bytes to determine the type of the file
  """

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
  Matches a file against known magic bytes.
  """
  def get_file_type(path) when is_binary(path) do
    case File.read(path) do
      {:ok, <<255, 216, _rest::binary>>} ->
        {:ok, :jpg}

      {:ok, <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>} ->
        {:ok, :png}

      {:ok, _} ->
        {:ok, :unknown}

      {:error, reason} ->
        {:error, List.to_string(:file.format_error(reason))}
    end
  end
end
