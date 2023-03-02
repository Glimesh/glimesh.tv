defmodule Glimesh.Chat.Token do
  @moduledoc """
  Embedded Schema used for Chat Message Tokens

  """
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :text, :string
    field :url, :string
    field :src, :string
    field :tenor_id, :string
    field :small_src, :string
  end

  def changeset(part, attrs \\ %{}) do
    part
    |> cast(attrs, [:type, :text, :url, :src, :tenor_id, :small_src])
    |> validate_required([:type, :text])
  end
end
