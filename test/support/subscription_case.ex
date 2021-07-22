defmodule GlimeshWeb.SubscriptionCase do
  use ExUnit.CaseTemplate

  import Phoenix.ChannelTest, only: [connect: 2]
  import Glimesh.AccountsFixtures

  @endpoint GlimeshWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with channels
      use GlimeshWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest, schema: Glimesh.Schema

      import GlimeshWeb.SubscriptionCase
    end
  end

  def setup_socket(_) do
    user = user_fixture()

    {:ok, client} =
      Boruta.Ecto.Admin.create_client(%{
        otp_app: :glimesh,
        authorization_code_ttl: 60,
        access_token_ttl: 60 * 60 * 24,
        name: "Test client"
      })

    {:ok, %{value: token}} =
      Boruta.Ecto.AccessTokens.create(
        %{
          client: struct(Boruta.Oauth.Client, Map.from_struct(client)),
          scope: "email chat streamkey"
        },
        refresh_token: false
      )

    {:ok, socket} =
      connect(GlimeshWeb.ApiSocket, %{
        "token" => token
      })

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    %{
      socket: socket,
      user: user
    }
  end
end
