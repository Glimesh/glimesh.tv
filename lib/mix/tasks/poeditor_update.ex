defmodule Mix.Tasks.Poeditor.Update do
  @moduledoc "Downloads updated translation files from POEditor. Please ensure you have the configuration applied!"
  @shortdoc "Downloads updated translation files from POEditor"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    api_token = Application.fetch_env!(:glimesh, :poeditor)[:api_token]
    project_id = Application.fetch_env!(:glimesh, :poeditor)[:project_id]
    languages = list_languages(api_token, project_id)

    Enum.map(languages, fn language ->
      if language["percentage"] > 60 do
        IO.puts("Exporting and setting up #{language["name"]} at #{language["percentage"]}%")

        lang_code = String.replace(language["code"], "-", "_")
        lang_path = Path.absname("priv/gettext/#{lang_code}/LC_MESSAGES")
        lang_file_path = Path.absname("priv/gettext/#{lang_code}/LC_MESSAGES/default.po")
        File.mkdir_p!(lang_path)

        export = export_language(api_token, project_id, language["code"])
        File.write!(lang_file_path, export)
        IO.puts("Wrote #{lang_file_path}")
      end
    end)

    IO.puts("Finished downloading translation files from POEditor!")
  end

  defp list_languages(api_token, project_id) do
    %HTTPoison.Response{status_code: 200, body: body} =
      HTTPoison.post!(
        "https://api.poeditor.com/v2/languages/list",
        {:form,
         [
           {"api_token", api_token},
           {"id", project_id}
         ]}
      )

    response = Jason.decode!(body)
    response["result"]["languages"]
  end

  defp export_language(api_token, project_id, lang_code) do
    %HTTPoison.Response{status_code: 200, body: body} =
      HTTPoison.post!(
        "https://api.poeditor.com/v2/projects/export",
        {:form,
         [
           {"api_token", api_token},
           {"id", project_id},
           {"language", lang_code},
           {"type", "po"}
         ]}
      )

    response = Jason.decode!(body)
    %HTTPoison.Response{body: po_body} = HTTPoison.get!(response["result"]["url"])
    po_body
  end
end
