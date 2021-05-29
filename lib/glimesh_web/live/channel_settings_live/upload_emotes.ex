defmodule GlimeshWeb.ChannelSettingsLive.UploadEmotes do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])
    channel = Glimesh.ChannelLookups.get_channel_for_user(user)
    can_upload = !is_nil(channel.emote_prefix)

    static_emotes = Glimesh.Emotes.list_static_emotes()
    animated_emotes = Glimesh.Emotes.list_animated_emotes()

    {:ok,
     socket
     |> put_page_title(gettext("Upload Channel Emotes"))
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:static_emotes, static_emotes)
     |> assign(:animated_emotes, animated_emotes)
     |> assign(:emote_settings, Glimesh.Streams.change_emote_settings(channel))
     |> assign(:can_upload, can_upload)
     |> assign(:uploaded_files, [])
     |> allow_upload(:emote, accept: ~w(.svg .gif), max_entries: 10)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :emote, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save_upload", %{"emotes" => emote_names}, socket) do
    attempted_uploads =
      consume_uploaded_entries(socket, :emote, fn %{path: path}, entry ->
        emote_name = Map.get(emote_names, entry.ref)

        emote_data =
          if String.ends_with?(entry.client_name, ".gif") or entry.client_type == "image/gif" do
            %{
              animated: true,
              animated_file: path
            }
          else
            %{
              animated: false,
              static_file: path
            }
          end

        Glimesh.Emotes.create_channel_emote(
          socket.assigns.user,
          socket.assigns.channel,
          Map.merge(
            %{
              emote: emote_name
            },
            emote_data
          )
        )
      end)

    {successful, errored} =
      Enum.split_with(attempted_uploads, fn {status, _} -> status == :ok end)

    successful_emotes = Enum.map(successful, fn {:ok, emote} -> emote end)

    errors =
      Enum.map(errored, fn {:error, changeset} ->
        Ecto.Changeset.traverse_errors(changeset, fn _, field, {msg, _opts} ->
          "#{field} #{msg}"
        end)
      end)
      |> Enum.flat_map(fn %{emote: errors} -> errors end)
      |> Enum.join(". ")

    {:noreply,
     socket
     |> put_flash(:info, "Successfully uploaded emotes")
     |> put_flash(:error, errors)
     |> update(:emotes, &(&1 ++ successful_emotes))}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_emote_settings", %{"channel" => attrs}, socket) do
    changeset =
      socket.assigns.channel
      |> Glimesh.Streams.change_emote_settings(attrs)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, emote_settings: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save_emote_settings", %{"channel" => attrs}, socket) do
    case Glimesh.Streams.update_emote_settings(socket.assigns.user, socket.assigns.channel, attrs) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(:channel, channel)
         |> assign(:can_upload, !is_nil(channel.emote_prefix))
         |> put_flash(:info, "Updated emote settings.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, emote_settings: changeset)}
    end
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  def prune_file_type(input) when is_binary(input) do
    input
    |> Path.rootname()
  end

  def prune_file_type(input) do
    input
  end
end
