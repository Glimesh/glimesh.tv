defmodule GlimeshWeb.GctLive.ManageEmotes do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:emote, accept: ~w(.png .jpg .jpeg), max_entries: 100)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :emote, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :emote, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:glimesh), "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)
        Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
