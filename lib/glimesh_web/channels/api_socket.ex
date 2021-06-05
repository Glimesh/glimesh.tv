defmodule GlimeshWeb.ApiSocket do
  @moduledoc """
  Allow for connections to the API socket with either an API token or a client id.

  Client ID is for read API access only.
  """
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: Glimesh.Schema

  @impl true
  def connect(%{"client_id" => client_id}, socket, _connect_info) do
    case Boruta.Config.clients().get_by(id: client_id) do
      {:ok, %Boruta.Oauth.Client{}} ->
        {:ok,
         socket
         |> assign(:user_id, nil)
         |> Absinthe.Phoenix.Socket.put_options(
           context: %{
             is_admin: false,
             current_user: nil,
             access_type: "app",
             access_identifier: client_id,
             user_access: %Glimesh.Accounts.UserAccess{}
           }
         )}

      _ ->
        case Glimesh.Oauth.TokenResolver.resolve_app(client_id) do
          {:ok, %Glimesh.OauthApplications.OauthApplication{}} ->
            {:ok,
             socket
             |> assign(:user_id, nil)
             |> Absinthe.Phoenix.Socket.put_options(
               context: %{
                 is_admin: false,
                 current_user: nil,
                 access_type: "app",
                 access_identifier: client_id,
                 user_access: %Glimesh.Accounts.UserAccess{}
               }
             )}

          _ ->
            :error
        end
    end
  end

  def connect(%{"token" => access_token}, socket, _connect_info) do
    case Boruta.Oauth.Authorization.AccessToken.authorize(value: access_token) do
      {:ok, %Boruta.Oauth.Token{} = token} ->
        case token.resource_owner do
          %Boruta.Oauth.ResourceOwner{} = resource_owner ->
            load_resource_owner(socket, token, resource_owner)

          _ ->
            {:ok,
             socket
             |> assign(:user_id, nil)
             |> Absinthe.Phoenix.Socket.put_options(
               context: %{
                 is_admin: false,
                 current_user: nil,
                 access_type: "user",
                 access_identifier: token.id,
                 user_access: %Glimesh.Accounts.UserAccess{}
               }
             )}
        end

      _ ->
        case Glimesh.Oauth.TokenResolver.resolve_user(access_token) do
          {:ok, %Glimesh.Accounts.UserAccess{} = user_access} ->
            {:ok,
             socket
             |> assign(:user_id, user_access.user.id)
             |> Absinthe.Phoenix.Socket.put_options(
               context: %{
                 is_admin: user_access.user.is_admin,
                 current_user: user_access.user,
                 access_type: "user",
                 access_identifier: user_access.user.username,
                 user_access: user_access
               }
             )}

          _ ->
            :error
        end
    end
  end

  def connect(_, _, _) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "api_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     GlimeshWeb.Endpoint.broadcast("api_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "api_socket:#{socket.assigns.user_id}"

  defp load_resource_owner(socket, token, resource_owner) do
    case Glimesh.Oauth.ResourceOwners.get_from(resource_owner) do
      %Glimesh.Accounts.User{} = user ->
        {:ok,
         socket
         |> assign(:user_id, user.id)
         |> Absinthe.Phoenix.Socket.put_options(
           context: %{
             is_admin: user.is_admin,
             current_user: user,
             access_type: "user",
             access_identifier: user.username,
             user_access: Glimesh.Oauth.Scopes.get_user_access(token.scope, user)
           }
         )}

      _ ->
        :error
    end
  end
end
