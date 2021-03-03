defmodule Glimesh do
  @moduledoc """
  Glimesh keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_version do
    Keyword.get(Application.spec(:glimesh), :vsn, "unknown")
  end

  def has_launched? do
    true
  end
end
