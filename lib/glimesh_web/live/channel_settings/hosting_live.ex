defmodule GlimeshWeb.ChannelSettings.HostingLive do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelHostsLookups
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelHosts

  alias GlimeshWeb.Components.Settings

  @impl true
  def mount(_params, _session, socket) do
    allow_hosting_changeset = Channel.change_allow_hosting(socket.assigns.channel)
    hosted_channels = ChannelHostsLookups.get_channel_hosting_list(socket.assigns.channel.id)

    {:ok,
     socket
     |> put_page_title(gettext("Hosting"))
     |> assign(form: to_form(allow_hosting_changeset))
     |> assign(
       :hosting_qualified,
       hosting_qualified?(socket.assigns.current_user, socket.assigns.channel)
     )
     |> assign(:allow_changeset, allow_hosting_changeset)
     |> assign(:matches, [])
     |> assign(:add_channel, "")
     |> assign(:add_channel_selected_value, "")
     |> assign(:hosted_channels, hosted_channels)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp hosting_qualified?(user, channel) do
    account_age = Glimesh.Accounts.get_account_age_in_days(user)
    total_streamed_hours = Glimesh.Streams.get_channel_hours(channel)

    user.confirmed_at != nil and account_age >= 5 and total_streamed_hours >= 10
  end

  defp search_for_channels(user, term) do
    ChannelLookups.search_hostable_channels_by_name(user, term)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"channel" => attrs}, socket) do
    form =
      socket.assigns.channel
      |> Channel.change_allow_hosting(attrs)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"channel" => attrs}, socket) do
    case Channel.update_allow_hosting(socket.assigns.channel, attrs) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(channel: channel)
         |> put_flash(:info, "Saved hosting preferences.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_allow_hosting", %{"channel" => channel_params}, socket) do
    case Channel.update_allow_hosting(socket.assigns.channel, channel_params) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(:channel, channel)
         |> assign(:allow_changeset, Channel.change_allow_hosting(channel))
         |> put_flash(:hosting_info, gettext("Saved Hosting Preference."))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :allow_changeset, changeset)}
    end
  end

  @impl true
  def handle_event("suggest", %{"add_channel" => add_channel}, socket) do
    matches = search_for_channels(socket.assigns.current_user, add_channel)

    {:noreply,
     assign(socket, matches: matches, add_channel: add_channel, add_channel_selected_value: "")}
  end

  @impl true
  def handle_event(
        "add_hosting_channel",
        %{"name" => channel_name, "selected" => selected},
        socket
      ) do
    # if the user copy/pastes or completely enters a channel name without using the picker, try to handle that scenario
    selected_value =
      if selected == "" and channel_name != "" do
        matches = search_for_channels(socket.assigns.current_user, channel_name)
        if length(matches) == 1, do: Enum.at(matches, 0).id, else: ""
      else
        selected
      end

    case ChannelHosts.add_new_host(
           socket.assigns.current_user,
           socket.assigns.channel,
           %ChannelHosts{hosting_channel_id: socket.assigns.channel.id},
           %{target_channel_id: selected_value}
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:matches, [])
         |> assign(:add_channel, "")
         |> assign(:add_channel_selected_value, "")
         |> put_flash(:hosting_info, gettext("Channel added"))
         |> redirect(to: ~p"/users/settings/hosting")}

      {:error, _channel_hosts} ->
        {:noreply,
         socket
         |> assign(matches: [])
         |> assign(add_channel_selected_value: "")
         |> put_flash(:error, gettext("Unable to add channel to hosting list"))}
    end
  end

  @impl true
  def handle_event(
        "add_channel_selection_made",
        %{"user_id" => _user_id, "username" => username, "channel_id" => channel_id},
        socket
      ) do
    {:noreply,
     socket
     |> assign(add_channel_selected_value: channel_id)
     |> assign(add_channel: username)}
  end

  @impl true
  def handle_event("remove_host", %{"id" => target_id}, socket) do
    channel_host = ChannelHosts.get_by_id(target_id)

    case ChannelHosts.delete_hosting_target(
           socket.assigns.current_user,
           socket.assigns.channel,
           channel_host
         ) do
      {:ok, _channel_host} ->
        {:noreply,
         socket
         |> put_flash(:hosting_info, gettext("Hosting target removed"))
         |> redirect(to: ~p"/users/settings/hosting")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Unable to remove hosting target"))}
    end
  end
end
