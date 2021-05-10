defmodule Glimesh.Oauth.Scopes do
  @moduledoc false

  import GlimeshWeb.Gettext

  def scope_gettext(scope) do
    case scope do
      "email" -> gettext("scopeemail")
      "chat" -> gettext("scopechat")
      "streamkey" -> gettext("scopestream")
    end
  end

  def get_user_access(scopes, user) do
    struct(
      Glimesh.Accounts.UserAccess,
      Map.merge(
        Enum.reduce(String.split(scopes), %{}, fn x, acc ->
          Map.put(acc, String.to_atom(x), true)
        end),
        %{user: user}
      )
    )
  end
end
