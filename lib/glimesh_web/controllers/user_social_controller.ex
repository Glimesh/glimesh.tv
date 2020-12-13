defmodule GlimeshWeb.UserSocialController do
  use GlimeshWeb, :controller

  def twitter(conn, params) do
    {:ok, access_token} = ExTwitter.access_token(params["oauth_verifier"], params["oauth_token"])

    # Configure ExTwitter to use your newly obtained access token
    ExTwitter.configure(
      consumer_key: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:consumer_key],
      consumer_secret: Application.get_env(:glimesh, Glimesh.Socials.Twitter)[:consumer_secret],
      access_token: access_token.oauth_token,
      access_token_secret: access_token.oauth_token_secret
    )

    case ExTwitter.verify_credentials() do
      %ExTwitter.Model.User{} = twitter_user ->
        # update user to set twitter username
        false

      _ ->
        # Something happened
        false
    end

    redirect(conn, to: Routes.user_settings_path(conn, :profile))
  end
end
