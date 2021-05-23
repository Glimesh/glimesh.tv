defmodule GlimeshWeb.GctLive.ManageEmotes do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])

    emotes = Glimesh.Emotes.list_all_emotes()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:emotes, emotes)
     |> assign(:uploaded_files, [])
     |> allow_upload(:emote, accept: ~w(.svg .gif), max_entries: 100)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :emote, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"emotes" => emote_names}, socket) do
    uploaded_emotes =
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

        {:ok, emote} =
          Glimesh.Emotes.create_global_emote(
            socket.assigns.user,
            Map.merge(
              %{
                emote: emote_name,
                approved_at: NaiveDateTime.utc_now()
              },
              emote_data
            )
          )

        emote
      end)

    {:noreply,
     socket
     |> put_flash(:info, "Successfully uploaded emotes")
     |> update(:emotes, &(&1 ++ uploaded_emotes))}
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
