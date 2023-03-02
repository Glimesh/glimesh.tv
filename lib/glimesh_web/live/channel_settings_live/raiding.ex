defmodule GlimeshWeb.ChannelSettingsLive.Raiding do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelLookups
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelBannedRaid

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])

    channel =
      ChannelLookups.get_channel_for_user(user, [
        :category,
        :user,
        banned_raid_channels: [banned_channel: [:user]]
      ])

    allow_raiding_changeset = Channel.change_allow_raiding(channel)
    only_allow_followed_changeset = Channel.change_only_allow_followed_raiding(channel)
    raid_message_changeset = Channel.change_raid_message(channel)

    {:ok,
     socket
     |> put_page_title(gettext("Raiding Settings"))
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:allow_changeset, allow_raiding_changeset)
     |> assign(:only_allow_followed_changeset, only_allow_followed_changeset)
     |> assign(:banned_channels, channel.banned_raid_channels)
     |> assign(:matches, [])
     |> assign(:ban_channel, "")
     |> assign(:ban_channel_selected_value, "")
     |> assign(:raid_message_changeset, raid_message_changeset)
     |> assign(:raid_message, channel.raid_message)}
  end

  @impl true
  def handle_event("toggle_allow_raiding", %{"channel" => channel_params}, socket) do
    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams.Policy,
             :update_channel,
             socket.assigns.user,
             socket.assigns.channel
           ) do
      case Channel.update_allow_raiding(socket.assigns.channel, channel_params) do
        {:ok, channel} ->
          {:noreply,
           socket
           |> assign(:channel, channel)
           |> assign(:allow_changeset, Channel.change_allow_raiding(channel))
           |> put_flash(:raiding_info, gettext("Saved Raiding Preference."))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :allow_changeset, changeset)}
      end
    end
  end

  def handle_event("toggle_only_allow_followed", %{"channel" => channel_params}, socket) do
    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams.Policy,
             :update_channel,
             socket.assigns.user,
             socket.assigns.channel
           ) do
      case Channel.update_only_allow_followed_raiding(socket.assigns.channel, channel_params) do
        {:ok, channel} ->
          {:noreply,
           socket
           |> assign(:channel, channel)
           |> assign(
             :only_allow_followed_changeset,
             Channel.change_only_allow_followed_raiding(channel)
           )
           |> put_flash(:raiding_info, gettext("Saved Raiding Preference."))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :allow_changeset, changeset)}
      end
    end
  end

  @impl true
  def handle_event("suggest", %{"ban_channel" => channel_name}, socket) do
    matches = search_for_channels(socket.assigns.channel, channel_name)

    {:noreply,
     assign(socket, matches: matches, ban_channel: channel_name, ban_channel_selected_value: "")}
  end

  @impl true
  def handle_event(
        "ban_raiding_channel",
        %{"name" => channel_name, "selected" => selected},
        socket
      ) do
    # if the user copy/pastes or completely enters a channel name without using the picker, try to handle that scenario
    selected_value =
      if selected == "" and channel_name != "" do
        matches = search_for_channels(socket.assigns.channel, channel_name)
        if length(matches) == 1, do: Enum.at(matches, 0).id, else: ""
      else
        selected
      end

    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams.Policy,
             :ban_raiding_channel,
             socket.assigns.user,
             socket.assigns.channel
           ) do
      case ChannelBannedRaid.insert_new_ban(socket.assigns.channel, selected_value) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:matches, [])
           |> assign(:ban_channel, "")
           |> assign(:ban_channel_selected_value, "")
           |> put_flash(:raiding_info, gettext("Channel banned from raiding"))
           |> redirect(to: ~p"/users/settings/raiding")}

        {:error, _channel_ban} ->
          {:noreply,
           socket
           |> assign(matches: [])
           |> assign(ban_channel_selected_value: "")
           |> put_flash(:error, gettext("Unable to ban channel from raiding"))}
      end
    end
  end

  @impl true
  def handle_event(
        "ban_channel_selection_made",
        %{"user_id" => _user_id, "username" => username, "channel_id" => channel_id},
        socket
      ) do
    {:noreply,
     socket
     |> assign(ban_channel_selected_value: channel_id)
     |> assign(ban_channel: username)}
  end

  @impl true
  def handle_event("unban_channel", %{"id" => target_id}, socket) do
    banned_raider =
      Glimesh.Repo.replica().get(ChannelBannedRaid, target_id)
      |> Glimesh.Repo.preload([:channel])

    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams.Policy,
             :unban_raiding_channel,
             socket.assigns.user,
             banned_raider.channel
           ) do
      case ChannelBannedRaid.remove_ban(banned_raider) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:raiding_info, gettext("Channel unbanned for raiding"))
           |> redirect(to: ~p"/users/settings/raiding")}

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Unable to unban channel for raiding"))}
      end
    end
  end

  def handle_event("save_raid_message", %{"channel" => channel_params}, socket) do
    with :ok <-
           Bodyguard.permit(
             Glimesh.Streams.Policy,
             :update_channel,
             socket.assigns.user,
             socket.assigns.channel
           ) do
      case Channel.update_raid_message(socket.assigns.channel, channel_params) do
        {:ok, channel} ->
          {:noreply,
           socket
           |> assign(:channel, channel)
           |> assign(:raid_message_changeset, Channel.change_raid_message(channel))
           |> assign(:raid_message, channel.raid_message)
           |> put_flash(:raiding_info, gettext("Saved Raiding Preference."))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :raid_message_changeset, changeset)}
      end
    end
  end

  defp search_for_channels(%Glimesh.Streams.Channel{} = channel, search_term) do
    Glimesh.ChannelLookups.search_bannable_raiding_channels_by_name(channel, search_term)
  end
end
