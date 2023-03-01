defmodule Glimesh.Socials.Twitter do
  @moduledoc """
  An OAuth1.1a strategy for Twitter.
  """
  use GlimeshWeb, :verified_routes

  # Public API

  def handle_user_connect(%Glimesh.Accounts.User{} = user, access_token) do
    ExTwitter.configure(
      consumer_key: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:consumer_key],
      consumer_secret: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:consumer_secret],
      access_token: access_token.oauth_token,
      access_token_secret: access_token.oauth_token_secret
    )

    try do
      %ExTwitter.Model.User{screen_name: screen_name, id_str: id} =
        ExTwitter.verify_credentials(skip_status: true)

      Glimesh.Socials.connect_user_social(user, "twitter", id, screen_name)
    rescue
      ExTwitter.Error -> {:error, "Failed to verify user"}
      ExTwitter.ConnectionError -> {:error, "Failed to verify user"}
    end
  end

  def authorize_url(_) do
    ExTwitter.configure(Application.get_env(:glimesh, Glimesh.Socials.Twitter))

    try do
      # Request twitter for a new token
      token = ExTwitter.request_token(~p"/users/social/twitter")

      # Generate the url for "Sign-in with twitter".
      # For "3-legged authorization" use ExTwitter.authorize_url instead
      {:ok, authenticate_url} = ExTwitter.authenticate_url(token.oauth_token)

      authenticate_url
    rescue
      MatchError -> nil
    end
  end
end
