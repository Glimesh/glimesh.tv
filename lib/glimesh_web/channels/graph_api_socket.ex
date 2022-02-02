defmodule GlimeshWeb.GraphApiSocket do
  @moduledoc """
  Allow for connections to the API socket with either an API token or a client id.

  Client ID is for read API access only.
  """
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: Glimesh.Api.Schema

  @impl true
  def connect(%{"client_id" => client_id}, socket, _connect_info) do
    with %Boruta.Oauth.Client{} = client <- Boruta.Config.clients().get_by(id: client_id),
         {:ok, %Glimesh.Api.Access{} = access} <-
           Glimesh.Oauth.get_unprivileged_api_access_from_client(client) do
      {:ok,
       socket
       |> assign(:user_id, nil)
       |> assign(:socket_id, client.id)
       |> Absinthe.Phoenix.Socket.put_options(
         context: %{
           access: access
         }
       )}
    else
      _ -> :error
    end
  end

  @impl true
  def connect(%{"token" => access_token}, socket, _connect_info) do
    with {:ok, %Boruta.Oauth.Token{} = token} <-
           Boruta.Oauth.Authorization.AccessToken.authorize(value: access_token),
         {:ok, %Glimesh.Api.Access{} = access} <-
           Glimesh.Oauth.get_api_access_from_token(token) do
      {:ok,
       socket
       |> assign(:user_id, access.user.id)
       |> assign(:socket_id, token.value)
       |> Absinthe.Phoenix.Socket.put_options(
         context: %{
           access: access
         }
       )}
    else
      _ -> :error
    end
  end

  def connect(_, _, _) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "graph_api_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     GlimeshWeb.Endpoint.broadcast("graph_api_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "graph_api_socket:#{socket.assigns.socket_id}"
end
