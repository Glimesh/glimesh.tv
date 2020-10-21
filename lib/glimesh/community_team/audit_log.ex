defmodule Glimesh.CommunityTeam.AuditLog do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "gct_audit_log" do
    belongs_to :user, Glimesh.Accounts.User

    field :action, :string
    field :target, :string
    field :verbose_required?, :boolean

    timestamps()
  end

  def changeset(audit_log, attrs \\ %{}) do
    audit_log
    |> cast(attrs, [:action, :target, :verbose_required?])
  end

end
