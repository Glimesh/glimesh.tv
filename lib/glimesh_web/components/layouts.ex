defmodule GlimeshWeb.Layouts do
  use GlimeshWeb, :html

  embed_templates("layouts/*")

  def html_root_tags(conn) do
    []
    |> site_theme_attribute(conn)
    |> lang_attribute(conn)
    |> Enum.join(" ")
  end

  defp site_theme_attribute(attributes, conn) do
    theme = site_theme(conn)
    ["data-theme=\"#{theme}\"" | attributes]
  end

  defp lang_attribute(attributes, conn) do
    locale = site_locale(conn)
    ["lang=\"#{locale}\"" | attributes]
  end

  def site_theme_label(conn) do
    case site_theme(conn) do
      "dark" -> "🌘"
      "light" -> "☀️"
    end
  end

  def site_locale_label(conn) do
    site_locale(conn)
  end

  def site_locale(conn) do
    case Plug.Conn.get_session(conn, :locale) do
      nil ->
        "en"

      locale ->
        locale
    end
  end

  def site_theme(conn) do
    case Plug.Conn.get_session(conn, :site_theme) do
      nil ->
        "dark"

      theme ->
        theme
    end
  end
end
