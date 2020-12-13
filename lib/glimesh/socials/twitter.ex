defmodule Glimesh.Socials.Twitter do
  @moduledoc """
  An OAuth2 strategy for Twitter.
  """

  # use OAuth2.Strategy

  # alias OAuth2.Strategy.AuthCode

  # Public API

  def client(oauth_client_params) do
    # OAuth2.Client.new(
    #   strategy: __MODULE__,
    #   client_id: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:client_id],
    #   client_secret: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:client_secret],
    #   redirect_uri: oauth_client_params.redirect_uri,
    #   site: "https://api.twitter.com",
    #   authorize_url: "https://api.twitter.com/oauth/authorize",
    #   token_url: "https://api.twitter.com/oauth2/token"
    # )
  end

  def authorize_url!(oauth_client_params \\ %{}, params \\ []) do
    ExTwitter.configure(Application.get_env(:glimesh, Glimesh.Socials.Twitter))

    # Request twitter for a new token
    token = ExTwitter.request_token("https://glimesh.dev/users/social/twitter")

    IO.inspect(token)

    # Generate the url for "Sign-in with twitter".
    # For "3-legged authorization" use ExTwitter.authorize_url instead
    {:ok, authenticate_url} = ExTwitter.authenticate_url(token.oauth_token)

    authenticate_url
  end

  def get_token!(oauth_client_params \\ %{}, params \\ [], headers \\ []) do
    # OAuth2.Client.get_token!(client(oauth_client_params), params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    # AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    # client
    # |> put_header("Accept", "application/json")
    # |> AuthCode.get_token(params, headers)
  end

  defp configure() do
  end
end
