defmodule GlimeshWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      {message, _} = error

      content_tag(:span, message,
        class: "invalid-feedback",
        phx_feedback_for: input_id(form, field)
      )
    end)
  end
end
