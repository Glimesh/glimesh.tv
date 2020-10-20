defmodule GlimeshWeb.ChannelModeratorView do
  use GlimeshWeb, :view

  def yes_or_no(inp) do
    if inp, do: gettext("Yes"), else: gettext("No")
  end
end
