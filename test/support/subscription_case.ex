defmodule GlimeshWeb.SubscriptionCase do
  use ExUnit.CaseTemplate

  import Phoenix.ChannelTest, only: [connect: 2]
  import Glimesh.AccountsFixtures

  @endpoint GlimeshWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with channels
      use GlimeshWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest, schema: Glimesh.OldSchema

      import GlimeshWeb.SubscriptionCase
    end
  end

  @spec setup_old_socket(any) :: %{socket: Phoenix.Socket.t(), user: any}
  def setup_old_socket(_) do
    user = user_fixture()

    {:ok, app} = Glimesh.ApiFixtures.app_fixture(user)

    {:ok, %Boruta.Oauth.Token{value: token}} =
      Boruta.Oauth.Authorization.token(%Boruta.Oauth.ClientCredentialsRequest{
        client_id: app.client.id,
        client_secret: app.client.secret,
        scope: "public email chat streamkey"
      })

    {:ok, socket} =
      connect(GlimeshWeb.OldApiSocket, %{
        "token" => token
      })

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    %{
      socket: socket,
      user: user
    }
  end
end
