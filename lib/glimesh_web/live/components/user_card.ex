defmodule GlimeshWeb.Components.UserCard do
  use GlimeshWeb, :live_component

  def render(assigns) do
    user = assigns.user

    ~H"""
      <div class="card">
        <div class="card-body">
            <h4 class={Glimesh.Chat.Effects.get_username_color(user, "text-color-link")}>
                <%= user.displayname %></h4>
            <div class="media flex-wrap">
                <img src={Glimesh.Avatar.url({user.avatar, user}, :original)} alt={user.displayname} height="128" class={["mr-3 img-avatar", if(Glimesh.Accounts.can_receive_payments?(user), do: "img-verified-streamer", else: "")]}>
                <div class="media-body">
                    <ul class="list-unstyled">
                        <li>
                            <strong><%= gettext("Joined:") %></strong>
                            <%= format_datetime(user.inserted_at) %>
                        </li>
                        <li>
                            <strong><%= gettext("Followers:") %></strong>
                            <%= Glimesh.AccountFollows.count_followers(user) %>
                        </li>
                        <li>
                            <strong><%= gettext("Following:") %></strong>
                            <%= Glimesh.AccountFollows.count_following(user) %>
                        </li>
                        <li>
                            <%= if twitter_user = Glimesh.Socials.get_social(user, "twitter") do %>
                            <span class="fa-stack" data-toggle="tooltip" title={gettext("Linked Twitter Account @%{username}", username: twitter_user.username)}>
                                <i class="fas fa-certificate fa-stack-2x" style="color:#007bff"></i>
                                <i class="fab fa-twitter fa-stack-1x"></i>
                            </span>
                            <% else %>
                            <br>
                            <% end %>
                        </li>
                    </ul>

                    <%= live_redirect gettext("Profile"), to: Routes.user_profile_path(@socket, :index, user.username), class: "btn btn-primary btn-sm" %>
                </div>
            </div>
        </div>
    </div>
    """
  end
end
