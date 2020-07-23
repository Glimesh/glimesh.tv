defmodule Glimesh.Streams.UserModerationLog do
  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User

  schema "user_moderation_log" do
    belongs_to :streamer, User
    belongs_to :moderator, User
    belongs_to :user, User
    field :action, :string

    timestamps()
  end

  @doc false
  def changeset(user_moderation_log, attrs) do
    user_moderation_log
    |> cast(attrs, [:action])
    |> validate_required([:streamer, :moderator, :user, :action])
  end
end
