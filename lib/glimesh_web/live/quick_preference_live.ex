defmodule GlimeshWeb.QuickPreferenceLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User

  @impl true
  def render(assigns) do
    ~L"""
    <li class="nav-item dropdown">
      <a href="javascript:void(0);" class="nav-link dropdown-toggle" id="settingsDropdown"
          data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          <%= @locale_emoji %> <%= @theme_emoji %>
      </a>
      <div class="dropdown-menu dropdown-menu-right" aria-labelledby="settingsDropdown">
        <%= f = form_for :preferences, "#quick-preferences", [phx_change: :save, class: "px-4 py-3"]%>
              <div class="form-group">
                  <label for="exampleDropdownFormEmail1">Site Language</label>
                  <%= select f, :locale, @locale_options, [selected: @locale] %>
              </div>
              <div class="form-group">
                  <label for="user_preference_Site Theme: ">Site Theme: </label>
                  <div class="custom-control custom-radio">
                      <%= radio_button f, :site_theme, "dark", [id: "darkMode", class: "custom-control-input"] %>
                      <label class="custom-control-label" for="darkMode"><%= gettext("Dark") %></label>
                  </div>
                  <div class="custom-control custom-radio">
                      <%= radio_button f, :site_theme, "light", [id: "lightMode", class: "custom-control-input"] %>
                      <label class="custom-control-label" for="lightMode"><%= gettext("Light") %></label>
                  </div>
              </div>
          </form>
      </div>
    </li>
    """
  end

  @impl true
  def mount(_params, %{"site_theme" => site_theme, "locale" => locale} = session, socket) do
    {
      :ok,
      socket
      |> assign(:current_user, Accounts.get_user_by_session_token(session["user_token"]))
      |> assign(:preferences, %{})
      |> assign(:theme_emoji, theme_emoji(site_theme))
      |> assign(:locale_emoji, locale_emoji(locale))
      |> assign(:locale, locale)
      |> assign(:locale_options, locale_options())
    }
  end

  @impl true
  def handle_event("save", %{"preferences" => preferences}, socket) do
    handle_save(socket.assigns.current_user, preferences, socket)
  end

  defp handle_save(%User{} = user, preferences, socket) do
    current_user_pref = Accounts.get_user_preference!(user)

    case Accounts.update_user_preference(current_user_pref, preferences) do
      {:ok, _} ->
        # conn
        # |> put_flash(:info, gettext("Preferences updated successfully."))
        # |> put_session(:user_return_to, Routes.user_settings_path(conn, :preference))
        # |> UserAuth.log_in_user(user)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Unexpected error saving preferences")}
    end
  end

  defp handle_save(nil, preferences, socket) do
    {:noreply, socket}
  end

  defp locale_options() do
    [
      English: "en",
      Español: "es",
      "Español rioplatense": "es_AR",
      "Español mexicano": "es_MX",
      Deutsch: "de",
      日本語: "ja",
      "Norsk Bokmål": "nb",
      Français: "fr",
      Svenska: "sv",
      "Tiếng Việt": "vi",
      Русский: "ru",
      한국어: "ko",
      Italiano: "it",
      български: "bg",
      Nederlands: "nl",
      Suomi: "fi",
      Polski: "pl",
      "Limba Română": "ro"
    ]
  end

  defp locale_emoji(locale) do
    locale
  end

  defp theme_emoji(theme) do
    case theme do
      "dark" -> "🌘"
      "light" -> "☀️"
    end
  end
end
