defmodule GlimeshWeb.AboutHTML do
  use GlimeshWeb, :html

  embed_templates "about/*"

  def markdown(input) do
    case Earmark.as_html(input) do
      {:ok, html_doc, []} ->
        html_doc

      {:ok, _, error_messages} ->
        raise "Error parsing markdown file"

      {:error, _, error_messages} ->
        raise "Error parsing markdown file"
    end
  end
end
