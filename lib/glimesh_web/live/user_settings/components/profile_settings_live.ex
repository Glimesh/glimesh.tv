defmodule GlimeshWeb.UserSettings.Components.ProfileSettingsLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> put_flash(:info, nil)
     |> assign(:edit_state, true)
     |> assign(
       :markdown,
       if session["user"].profile_content_md do
        session["user"].profile_content_md
       else
        gettext("Welcome to my profile! I haven't customized it yet, but I can easily do that by clicking my username up in the right hand corner!")
       end
     )
     |> assign(:profile_changeset, session["profile_changeset"])
     |> assign(:raw_markdown, session["user"].profile_content_md)
     |> assign(:twitter_auth_url, session["twitter_auth_url"])
     |> assign(:user, session["user"])
     |> assign(:route, session["route"])}
  end

  @impl true
  def handle_event("change_state", %{"state" => edit_state}, socket) do
    if edit_state == "preview" do

      {:noreply,
       socket
       |> assign(:markdown, elem(Earmark.as_html(socket.assigns.markdown), 1))
       |> assign(:edit_state, false)}
    else
      {:noreply,
       socket
       |> assign(:markdown, socket.assigns.markdown)
       |> assign(:edit_state, true)}
    end
  end

  def handle_event("update_markdown", params, socket) do
    if params["user"]["profile_content_md"] != socket.assigns.markdown do
      {:noreply,
       socket
       |> assign(:edit_state, true)
       |> assign(:markdown, params["user"]["profile_content_md"])
       |> assign(:raw_markdown, params["user"]["profile_content_md"])}
    else
      {:noreply, socket}
    end
  end
end
