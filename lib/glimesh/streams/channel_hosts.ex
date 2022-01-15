defmodule Glimesh.Streams.ChannelHosts do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema

  alias Glimesh.Accounts.User
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelHosts

  import Ecto.{Changeset, Query}
  import GlimeshWeb.Gettext

  schema "channel_hosts" do
    belongs_to :host, Glimesh.Streams.Channel, source: :hosting_channel_id
    belongs_to :target, Glimesh.Streams.Channel, source: :target_channel_id

    field :hosting_channel_id, :integer
    field :target_channel_id, :integer
    field :status, :string, default: "ready"
    field :last_hosted_date, :naive_datetime

    timestamps()
  end

  def changeset(channel_hosts, attrs \\ %{}) do
    channel_hosts
    |> cast(attrs, [:hosting_channel_id, :target_channel_id, :status, :last_hosted_date])
    |> unique_constraint([:hosting_channel_id, :target_channel_id])
    |> validate_required([:hosting_channel_id, :target_channel_id, :status])
    |> validate_hosting_qualifications()
    |> validate_target_qualifications()
  end

  defp validate_hosting_qualifications(changeset) do
    host_channel_id = get_field(changeset, :hosting_channel_id)
    target_channel_id = get_field(changeset, :target_channel_id)
    host_channel = Glimesh.ChannelLookups.get_channel(host_channel_id)
    host_channel_hours = Glimesh.Streams.get_channel_hours(host_channel)

    validate_host_query =
      from(user in User,
        join: ch in Channel,
        on: user.id == ch.user_id,
        where: ch.id == ^host_channel_id,
        where: ch.inaccessible == false,
        where: not is_nil(user.confirmed_at),
        where: user.is_banned == false,
        where: user.can_stream == true,
        where:
          fragment(
            "((extract(epoch from now()) - extract(epoch from ?)) / 86400) >= 5",
            user.inserted_at
          ),
        where:
          fragment(
            "not exists(select user_id from channel_bans where user_id = ? and channel_id = ? and expires_at is null)",
            user.id,
            ^target_channel_id
          )
      )

    if Repo.exists?(validate_host_query) and host_channel_hours >= 10 do
      changeset
    else
      add_error(
        changeset,
        :hosting_channel_id,
        gettext("Host channel does not meet hosting requirements")
      )
    end
  end

  def validate_target_qualifications(changeset) do
    target_channel_id = get_field(changeset, :target_channel_id)

    if target_channel_id do
      validate_target_query =
        from(user in User,
          join: channel in Channel,
          on: user.id == channel.user_id,
          where: channel.id == ^target_channel_id,
          where: user.can_stream == true,
          where: user.is_banned == false,
          where: not is_nil(user.confirmed_at),
          where: channel.inaccessible == false,
          where: channel.allow_hosting == true
        )

      if Repo.exists?(validate_target_query) do
        changeset
      else
        add_error(
          changeset,
          :target_channel_id,
          gettext("Target channel does not qualify for hosting")
        )
      end
    else
      add_error(changeset, :target_channel_id, gettext("Target channel id is required"))
    end
  end

  def add_new_host(
        %User{} = user,
        %Channel{} = channel,
        %ChannelHosts{} = channel_hosts,
        attrs \\ %{}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Streams.Policy, :add_hosting_target, user, channel) do
      channel_hosts
      |> changeset(attrs)
      |> Repo.insert()
    end
  end

  def delete_hosting_target(%User{} = user, %Channel{} = channel, %ChannelHosts{} = channel_hosts) do
    with :ok <- Bodyguard.permit(Glimesh.Streams.Policy, :delete_hosting_target, user, channel) do
      channel_hosts
      |> Repo.delete()
    end
  end

  def get_by_id(id) do
    Repo.get_by(ChannelHosts, id: id)
  end
end
