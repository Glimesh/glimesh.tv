defmodule GlimeshWeb.UserSocket do
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: Glimesh.Schema

  alias Glimesh.Accounts.User

  ## Channels
  # channel "room:*", GlimeshWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Glimesh.Oauth.TokenResolver.resolve_user(token) do
      {:ok, %User{} = user} ->
        {:ok,
         socket
         |> assign(:user_id, user.id)
         |> Absinthe.Phoenix.Socket.put_options(
           context: %{
             is_admin: user.is_admin,
             current_user: user
           }
         )}

      _ ->
        :error
    end
  end

  def connect(_, _, _) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     GlimeshWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
