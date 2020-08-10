defmodule GlimeshWeb.Plugs.Locale do
  import Plug.Conn

  def init(_opts), do: nil

  @locales Gettext.known_locales(GlimeshWeb.Gettext)
  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) when locale in @locales do
    Gettext.put_locale(GlimeshWeb.Gettext, locale)
    conn = put_resp_cookie conn, "locale", locale, max_age: 10*24*60*60
    conn
  end

  def call(conn, _opts) do
    case locale_from_user(conn) || locale_from_cookies(conn) || locale_from_params(conn) do
      nil -> conn
      locale ->
        Gettext.put_locale(GlimeshWeb.Gettext, locale)
        conn = conn |> persist_locale(locale)
        conn
    end
  end

  def locale_from_params(conn) do
    conn.params["locale"] |> validate_locale
  end

  def locale_from_cookies(conn) do
    conn.cookies["locale"] |> validate_locale
  end

  def locale_from_user(conn) do
    conn.assigns.current_user.locale |> validate_locale
  end

  defp validate_locale(locale) when locale in @locales, do: locale

  defp validate_locale(_locale), do: nil

  defp persist_locale(conn, new_locale) do
    if conn.cookies["locale"] != new_locale do
      conn |> put_resp_cookie("locale", new_locale, max_age: 10*24*60*60)
    else
      conn
    end
  end

end
