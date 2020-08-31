defmodule Glimesh.Schema.DataTypes do
  @moduledoc """
  Data Types for the GraphQL API
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers
  alias Glimesh.Repo

  import_types(Absinthe.Type.Custom)

  @desc "A chat message sent to a channel by a user."
  object :chat_message do
    field :id, :id
    field :message, :string, description: "The chat message."

    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)
  end
end
