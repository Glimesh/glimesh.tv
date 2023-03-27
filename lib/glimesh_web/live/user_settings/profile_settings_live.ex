defmodule GlimeshWeb.UserSettings.ProfileSettingsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts.Profile
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, session, socket) do
    pronouns_list = Profile.list_pronouns()

    {:ok,
     socket
     |> put_page_title(gettext("Profile"))
     |> assign(
       :form,
       to_form(Glimesh.Accounts.change_user_profile(socket.assigns.current_user, %{}))
     )
     |> assign(
       :twitter_account,
       Glimesh.Socials.get_social(socket.assigns.current_user, "twitter")
     )
     |> assign(:pronouns, pronouns_list)
     |> assign(:raw_markdown, socket.assigns.current_user.profile_content_md)
     |> assign(:formatted_markdown, socket.assigns.current_user.profile_content_html)
     |> assign(:markdown_state, "edit")}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_state", %{"state" => "edit"}, socket) do
    {:noreply, assign(socket, :markdown_state, "edit")}
  end

  def handle_event("edit_state", %{"state" => "preview"}, socket) do
    markdown = socket.assigns.raw_markdown |> Profile.safe_user_markdown_to_html() |> elem(1)

    {:noreply,
     socket
     |> assign(:formatted_markdown, markdown)
     |> assign(:markdown_state, "preview")}
  end

  def handle_event("update_markdown", value, socket) do
    {:noreply, assign(socket, :raw_markdown, value["user"]["profile_content_md"])}
  end
end
