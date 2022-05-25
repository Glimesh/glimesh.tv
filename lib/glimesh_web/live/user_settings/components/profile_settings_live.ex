defmodule GlimeshWeb.UserSettings.Components.ProfileSettingsLive do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts.Profile

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    pronouns_list = Profile.list_pronouns()

    {:ok,
     socket
     |> put_flash(:info, nil)
     |> assign(:profile_changeset, session["profile_changeset"])
     |> assign(:twitter_auth_url, session["twitter_auth_url"])
     |> assign(:twitter_account, Glimesh.Socials.get_social(session["user"], "twitter"))
     |> assign(:user, session["user"])
     |> assign(:route, session["route"])
     |> assign(:pronouns, pronouns_list)
     |> assign(:raw_markdown, session["user"].profile_content_md)
     |> assign(:formatted_markdown, session["user"].profile_content_html)
     |> assign(:markdown_state, "edit")
    }
  end

  def handle_event("edit_state", %{"state" => "edit"}, socket) do
    {:noreply, assign(socket, :markdown_state, "edit")}
  end

  def handle_event("edit_state", %{"state" => "preview"}, socket) do
    markdown = socket.assigns.raw_markdown |> Profile.safe_user_markdown_to_html() |> elem(1)
    {:noreply, socket
    |> assign(:formatted_markdown, markdown)
    |> assign(:markdown_state, "preview")}
  end

  def handle_event("update_markdown", value, socket) do
    {:noreply, assign(socket, :raw_markdown, value["user"]["profile_content_md"])}
  end
end
