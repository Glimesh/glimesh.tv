defmodule Glimesh.Accounts.Profile do
  def safe_user_markdown_to_html(profile_content_md) do
    {:ok, html_doc, []} = Earmark.as_html(profile_content_md)
    html_doc |> HtmlSanitizeEx.basic_html()
  end
end
