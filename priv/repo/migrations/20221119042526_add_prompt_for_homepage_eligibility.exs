defmodule Glimesh.Repo.Migrations.AddPromptForHomepageEligibility do
  use Ecto.Migration

  def change do
    create_prompt_homepage_type_enum =
      "CREATE TYPE homepage_prompt_type AS ENUM('ineligible', 'prompt', 'ignore')"

    drop_prompt_homepage_type_enum = "DROP TYPE homepage_prompt_type"

    execute(create_prompt_homepage_type_enum, drop_prompt_homepage_type_enum)

    alter table(:channels) do
      add :prompt_for_homepage, :homepage_prompt_type, default: "ineligible"
    end
  end
end
