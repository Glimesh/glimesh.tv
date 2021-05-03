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
end
