defmodule Glimesh.Repo.Migrations.FixAvatarUrlPaths do
  use Ecto.Migration

  def change do
    Enum.each(Glimesh.Accounts.list_users(), fn user ->
      if user.avatar do
        avatar_url = Glimesh.Avatar.url({user.avatar, user}, :original_x2)
        if String.starts_with?(avatar_url, "https") do
          {:ok, resp} = :httpc.request(:get, {avatar_url, []}, [], [body_format: :binary])
          {{_, 200, 'OK'}, _headers, body} = resp

          File.write!("/tmp/#{user.username}.png", body)
          Glimesh.Accounts.User.profile_changeset(user, %{avatar: %Plug.Upload{
            path: "/tmp/#{user.username}.png",
            content_type: "image/png",
            filename: "#{user.username}.png"
          }, displayname: user.displayname})
          File.rm("/tmp/#{user.username}.png")
        else
          {:ok, resp} = :httpc.request(:get, {'https://glimesh-user-assets.nyc3.cdn.digitaloceanspaces.com/uploads/avatars/WildWolf.png?v=63773159726', []}, [], [body_format: :binary])
          {{_, 200, 'OK'}, _headers, body} = resp

          File.write!("/tmp/#{user.username}.png", body)
          Glimesh.Accounts.User.profile_changeset(user, %{avatar: %Plug.Upload{
            path: "/tmp/#{user.username}.png",
            content_type: "image/png",
            filename: "#{user.username}.png"
          }, displayname: user.displayname})
          File.rm("/tmp/#{user.username}.png")
        end
      end
    end)
  end
end
