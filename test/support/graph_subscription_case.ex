defmodule GlimeshWeb.GraphSubscriptionCase do
  use ExUnit.CaseTemplate

  import Phoenix.ChannelTest, only: [connect: 2]
  import Glimesh.AccountsFixtures

  @endpoint GlimeshWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with channels
      use GlimeshWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest, schema: Glimesh.Api.Schema

      import GlimeshWeb.GraphSubscriptionCase
    end
  end

  @spec setup_socket(any) :: %{socket: Phoenix.Socket.t(), user: any}
  def setup_socket(_) do
    user = user_fixture()

    {:ok, app} = Glimesh.ApiFixtures.app_fixture(user)

    {:ok, %Boruta.Oauth.Token{value: token}} =
      Boruta.Oauth.Authorization.token(%Boruta.Oauth.ClientCredentialsRequest{
        client_id: app.client.id,
        client_secret: app.client.secret,
        scope: "public email chat streamkey follow"
      })

    {:ok, socket} =
      connect(GlimeshWeb.GraphApiSocket, %{
        "token" => token
      })

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    %{
      socket: socket,
      user: user
    }
  end

  @spec setup_anonymous_socket(any) :: %{socket: Phoenix.Socket.t(), user: any}
  def setup_anonymous_socket(_) do
    user = user_fixture()

    {:ok, app} = Glimesh.ApiFixtures.app_fixture(user)

    {:ok, socket} =
      connect(GlimeshWeb.GraphApiSocket, %{
        "client_id" => app.client.id
      })

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    %{
      socket: socket,
      user: user
    }
  end
end
