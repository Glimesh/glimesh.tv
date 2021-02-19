defmodule GlimeshWeb.UserPaymentsView do
  use GlimeshWeb, :view

  def truthy_checkbox(true) do
    Phoenix.HTML.raw("<i class=\"fas fa-check\"></i>")
  end

  def truthy_checkbox(false) do
    Phoenix.HTML.raw("<i class=\"fas fa-times\"></i>")
  end
end
