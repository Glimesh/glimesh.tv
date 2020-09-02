defmodule GlimeshWeb.Oauth2Provider.AuthorizationView do
  use GlimeshWeb, :view

  def scope_gettext(text) do
    case text do
      "public" -> gettext("scopepublic")
      "email" -> gettext("scopeemail")
      "chat" -> gettext("scopechat")
      "stream" -> gettext("scopestream")
    end
  end
end
