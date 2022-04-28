defmodule GlimeshWeb.ChannelSettingsLive.UploadEmotes do
  use GlimeshWeb, :live_view

  alias Glimesh.Emotes
  alias Glimesh.Streams

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])
    channel = Glimesh.ChannelLookups.get_channel_for_user(user)
    can_upload = !is_nil(channel.emote_prefix)

    # Temporarily not allowing gifs
    {:ok,
     socket
     |> put_page_title(gettext("Upload Channel Emotes"))
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:emote_settings, Streams.change_emote_settings(channel))
     |> assign(:can_upload, can_upload)
     |> assign(:uploaded_files, [])
     |> allow_upload(:emote, accept: ~w(.svg .gif), max_entries: 2)}
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

        case Emotes.create_channel_emote(
               socket.assigns.user,
               socket.assigns.channel,
               Map.merge(
                 %{
                   emote: emote_name
                 },
                 emote_data
               )
             ) do
          {:ok, emote} ->
            {:ok, {:ok, emote}}

          {:error, changeset} ->
            {:postpone, {:error, changeset}}
        end
      end)

    {_, errored} = Enum.split_with(attempted_uploads, fn {status, _} -> status == :ok end)

    errors =
      Enum.map(errored, fn {:error, changeset} ->
        Ecto.Changeset.traverse_errors(changeset, fn _, field, {msg, _opts} ->
          "#{field} #{msg}"
        end)
      end)
      |> Enum.flat_map(fn input ->
        case input do
          %{emote: errors} -> errors
          %{static_file: _errors} -> ["Please review the emote requirements before uploading."]
          %{animated_file: _errors} -> ["Please review the emote requirements before uploading."]
          _ -> ["Unexpected file input"]
        end
      end)

    if length(errors) > 0 do
      {:noreply,
       socket
       |> put_flash(:emote_error, Enum.join(errors, ". "))
       |> redirect(to: Routes.user_settings_path(socket, :emotes))}
    else
      {:noreply,
       socket
       |> put_flash(
         :emote_info,
         "Successfully uploaded emotes, pending review by the Glimesh Community Team"
       )
       |> redirect(to: Routes.user_settings_path(socket, :emotes))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_emote_settings", %{"channel" => attrs}, socket) do
    changeset =
      socket.assigns.channel
      |> Streams.change_emote_settings(attrs)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, emote_settings: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save_emote_settings", %{"channel" => attrs}, socket) do
    case Streams.update_emote_settings(socket.assigns.user, socket.assigns.channel, attrs) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(:channel, channel)
         |> assign(:can_upload, !is_nil(channel.emote_prefix))
         |> put_flash(:info, "Updated channel emote settings.")}

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
