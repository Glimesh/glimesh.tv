defmodule Glimesh.CommunityTeam do
  @moduledoc """
  The Community Team context :)
  """
  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.CommunityTeam.AuditLog
  alias Glimesh.Repo

  defdelegate authorize(action, user, params), to: Glimesh.CommunityTeam.Policy

  def access_level_to_title(level) do
    case level do
      5 -> "Admin"
      4 -> "Manager"
      3 -> "Team Lead"
      2 -> "Team Member"
      1 -> "Trial Member"
      _ -> "None"
    end
  end

  # Audit Log related functions
  def create_audit_entry(user, attrs \\ %{action: "None", target: "None"}) do
    %AuditLog{
      user: user
    }
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  def create_lookup_audit_entry(gct_user, target) do
    attrs = %{
      action: "lookup",
      target: target.username,
      verbose_required: true
    }

    %AuditLog{
      user: gct_user
    }
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  def list_all_audit_entries(include_verbose? \\ false, params \\ []) do
    case include_verbose? do
      true ->
        AuditLog |> order_by(desc: :inserted_at) |> preload(:user) |> Repo.paginate(params)

      false ->
        AuditLog
        |> order_by(desc: :inserted_at)
        |> where([al], al.verbose_required == false)
        |> preload(:user)
        |> Repo.paginate(params)
    end
  end

  def get_audit_log_entry_from_id!(id) do
    Repo.one(
      from al in AuditLog,
        where: al.id == ^id
    )
    |> Repo.preload([:user])
  end

  def log_unauthorized_access(current_user) do
    create_audit_entry(current_user, %{
      action: "Unauthorized access",
      target: "None",
      verbose_required: false
    })
  end

  def generate_update_user_profile_more_details(user, user_params) do
    _fancy_string = """
    Display name changed from #{user.displayname} to #{user_params["displayname"]}
    Language changed from #{user.locale} to #{user_params["locale"]}
    Twitter social changed from #{user.social_twitter} to #{user_params["social_twitter"]}
    YouTube social changed from #{user.social_youtube} to #{user_params["social_youtube"]}
    Instagram social changed from #{user.social_instagram} to #{user_params["social_instagram"]}
    Discord social changed from #{user.social_discord} to #{user_params["social_discord"]}
    YouTube URL changed from #{user.youtube_intro_url} to #{user_params["youtube_intro_url"]}
    """
  end

  def generate_update_user_more_details(user, user_params) do
    _fancy_string = """
    Display name changed from #{user.displayname} to #{user_params["displayname"]}
    Username changed from #{user.username} to #{user_params["username"]}
    Email changed from #{user.email} to #{user_params["email"]}
    Language changed from #{user.locale} to #{user_params["locale"]}
    Admin changed from #{user.is_admin} to #{user_params["is_admin"]}
    Can stream changed from #{user.can_stream} to #{user_params["can_stream"]}
    Stripe user id changed from #{user.stripe_user_id} to #{user_params["stripe_user_id"]}
    Stripe customer id changed from #{user.stripe_customer_id} to #{
      user_params["stripe_customer_id"]
    }
    Stripe payment method changed from #{user.stripe_payment_method} to #{
      user_params["stripe_payment_method"]
    }
    2FA changed from #{user.tfa_token} to #{user_params["tfa_token"]}
    Payments enabled changed from #{user.can_payments} to #{user_params["can_payments"]}
    GCT changed from #{user.is_gct} to #{user_params["is_gct"]}
    GCT Access changed from #{user.gct_level} to #{user_params["gct_level"]}
    Banned changed from #{user.is_banned} to #{user_params["is_banned"]}
    """
  end

  def generate_update_channel_more_details(channel, channel_params) do
    _fancy_string = """
    Title changed from #{channel.title} to #{channel_params["title"]}
    Category changed from #{channel.category_id} to #{channel_params["category_id"]}
    Disable hyperlinks changed from #{channel.disable_hyperlinks} to #{
      channel_params["disable_hyperlinks"]
    }
    Block links changed from #{channel.block_links} to #{channel_params["block_links"]}
    """
  end

  # End of audit log functions

  # Editing user functions
  def change_user(user, attrs \\ %{}) do
    User.gct_user_changeset(user, attrs)
  end

  def update_user(user, attrs) do
    user
    |> User.gct_user_changeset(attrs)
    |> Repo.update()
  end

  # End of editing user functions
end
