defmodule GlimeshWeb.Users.NotificationsLive do
  use GlimeshWeb, :user_settings_live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User

  alias Glimesh.ChannelLookups

  def render(assigns) do
    ~H"""
    <div class="container">
      <h2 class="mt-4"><%= gettext("Notifications") %></h2>

      <.form :let={f} for={@changeset} id="notifications" phx-change="save">
        <div class="card">
          <div class="card-header">
            <h4><%= gettext("Newsletter Subscriptions") %></h4>
          </div>
          <div class="card-body">
            <div class="custom-control custom-switch">
              <%= checkbox(f, :allow_glimesh_newsletter_emails, class: "custom-control-input") %>
              <%= label(
                f,
                :allow_glimesh_newsletter_emails,
                gettext("Allow Glimesh Newsletter Emails"),
                class: "custom-control-label"
              ) %>
              <%= error_tag(f, :allow_glimesh_newsletter_emails) %>
              <p>
                <%= gettext(
                  "Newsletter emails are our general marketing, product updates, and new feature announcements. We'll
                    send emails about upcoming events or new product launches or availability."
                ) %>
              </p>
            </div>
            <!--
            <div class="custom-control custom-switch">
                <input type="checkbox" class="custom-control-input" id="customSwitch1" checked>
                <label class="custom-control-label" for="customSwitch1">Allow Developer Update Emails</label>
                <p>Whenever we make breaking changes to the features of our website, or the API we'll notify this email
                    list to make sure our developer community is up to date.</p>
            </div>

            <div class="custom-control custom-switch">
                <input type="checkbox" class="custom-control-input" id="customSwitch1" checked>
                <label class="custom-control-label" for="customSwitch1">Allow Company Update Emails</label>
                <p>We'll send quarterly company updates on our financials, news, and more.</p>
            </div>
            -->
          </div>
        </div>

        <div class="card mt-4">
          <div class="card-header">
            <h4><%= gettext("Live Channel Notifications") %></h4>
          </div>
          <div class="card-body">
            <p>
              <%= gettext(
                "If enabled, we can send alerts whenever your favorite followed streams go live. To get live notifications you must be following the channel, with the bell checked, and \"Allow Live Subscriptions\" must be enabled below."
              ) %>
            </p>

            <div class="custom-control custom-switch">
              <%= checkbox(f, :allow_live_subscription_emails, class: "custom-control-input") %>
              <%= label(f, :allow_live_subscription_emails, gettext("Allow Live Channel Emails"),
                class: "custom-control-label"
              ) %>
              <%= error_tag(f, :allow_live_subscription_emails) %>
              <p>
                <%= gettext(
                  "Disallowing Live Subscriptions will disable them across the board, even if you have channels listed
                    below. If you allow the notifications you'll start getting going live emails for the listed
                    channels."
                ) %>
              </p>
            </div>

            <div class="row">
              <%= for live_sub <- @channel_live_subscriptions do %>
                <div class="col-md-3">
                  <div class="card">
                    <div class="card-body">
                      <h5 class="card-title"><%= live_sub.streamer.displayname %></h5>
                      <button
                        id={"streamer-#{live_sub.streamer.id}"}
                        type="button"
                        phx-click="remove_live_notification"
                        phx-value-streamer={live_sub.streamer.id}
                        class="btn btn-danger btn-sm"
                      >
                        <%= gettext("Disable Live Notifications") %>
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </.form>

      <div class="card mt-4">
        <div class="card-header">
          <h4><%= gettext("Your Email Log") %></h4>
        </div>
        <div class="card-body">
          <p>
            <%= gettext(
              "This is a list of all of the emails we have sent you and what triggered them. Only shows the last 50 sent
                emails."
            ) %>
          </p>

          <table class="table">
            <thead>
              <tr>
                <th><%= gettext("Type of Email") %></th>
                <th><%= gettext("Subject") %></th>
                <th><%= gettext("Sent At") %></th>
              </tr>
            </thead>
            <tbody>
              <%= for log <- @email_log do %>
                <tr>
                  <td><%= log.type %></td>
                  <td><%= log.subject %></td>
                  <td><%= log.inserted_at %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user

    changeset = Accounts.change_user_notifications(user)

    channel_live_subscriptions = ChannelLookups.list_followed_live_notification_channels(user)

    email_log = Glimesh.Emails.list_email_log(user)

    {:ok,
     socket
     |> put_page_title("Notifications")
     |> assign(:email_log, email_log)
     |> assign(:changeset, changeset)
     |> assign(:channel_live_subscriptions, channel_live_subscriptions)
     |> assign(:current_user, user)}
  end

  @impl true
  def handle_event("remove_live_notification", %{"streamer" => streamer_id}, socket) do
    streamer = Accounts.get_user!(streamer_id)
    following = Glimesh.AccountFollows.get_following(streamer, socket.assigns.current_user)

    case Glimesh.AccountFollows.update_following(following, %{
           has_live_notifications: false
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Disabled live channel notifications for %{streamer}",
             streamer: streamer.displayname
           )
         )
         |> assign(
           :channel_live_subscriptions,
           ChannelLookups.list_followed_live_notification_channels(socket.assigns.current_user)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Glimesh.Accounts.update_user_notifications(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:changeset, Accounts.change_user_notifications(user))
         |> assign(:current_user, user)
         |> put_flash(:info, gettext("Saved notification preferences."))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
