defmodule Glimesh.Accounts.UserAccess do
  @moduledoc """
  Something about a user and their permissions
  """

  defstruct user: nil, public: false, email: false, chat: false, streamkey: false
end
