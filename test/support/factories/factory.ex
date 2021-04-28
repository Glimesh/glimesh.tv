defmodule Glimesh.Factory do
  @moduledoc """
  Import module for factories.
  When creating a factory, you must add it here to use the Glimesh.Factory namespace
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  use Glimesh.CategoryFactory
  use Glimesh.ChannelFactory
  use Glimesh.FollowerFactory
  use Glimesh.StreamFactory
  use Glimesh.SubcategoryFactory
  use Glimesh.TagFactory
  use Glimesh.UserFactory
  use Glimesh.ChatMessageFactory
end
