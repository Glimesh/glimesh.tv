defmodule Glimesh.Resolvers.StreamsResolver do
  @moduledoc false
  alias Glimesh.Streams

  def all_channels(_, _) do
    {:ok, Streams.list_channels()}
  end

  def find_channel(%{username: username}, _) do
    {:ok, Streams.get_channel_for_username!(username)}
  end

  def all_categories(_, _) do
    {:ok, Streams.list_categories()}
  end

  def find_category(%{slug: slug}, _) do
    {:ok, Streams.get_category!(slug)}
  end
end
