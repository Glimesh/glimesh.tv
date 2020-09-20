defmodule GlimeshWeb.DebugController do
  @moduledoc false
  use GlimeshWeb, :controller

  def getEmotes(conn, _) do
    json(conn, Enum.map(Glimesh.Chat.list_chat_messages(%{id: 1}), fn messages -> messages.message end))
  end
end
