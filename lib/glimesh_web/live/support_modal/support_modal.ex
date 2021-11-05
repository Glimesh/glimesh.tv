defmodule GlimeshWeb.SupportModal do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @valid_tabs [
    "subscription",
    "donate",
    "streamloots"
  ]

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    open_tab =
      user_input_tab(session["tab"], default_tab(can_receive_payments, channel.streamloots_url))

    {:ok,
     socket
     |> assign(:show_modal, Map.get(session, "shown", false))
     |> assign(:site_theme, session["site_theme"])
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:can_receive_payments, can_receive_payments)
     |> assign(:is_the_streamer, false)
     |> assign(:tab, open_tab)
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    open_tab =
      user_input_tab(session["tab"], default_tab(can_receive_payments, channel.streamloots_url))

    async_success_message =
      if session_id = Map.get(session, "stripe_session_id") do
        case Stripe.Session.retrieve(session_id) do
          {:ok, %Stripe.Session{payment_status: "paid"}} ->
            "Your purchase has completed successfully! You can close this window to get back to the stream."

          _ ->
            nil
        end
      end

    {:ok,
     socket
     |> assign(:async_success_message, async_success_message)
     |> assign(:show_modal, Map.get(session, "shown", false))
     |> assign(:site_theme, session["site_theme"])
     |> assign(:is_the_streamer, streamer.id == user.id)
     |> assign(:can_receive_payments, can_receive_payments)
     |> assign(:tab, open_tab)
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:user, user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="supportModal" class="live-modal" phx-capture-click="hide_modal" phx-window-keydown="hide_modal" phx-key="escape" phx-target="#supportModal" phx-page-loading>
      <div class="modal-dialog modal-lg" role="document">
          <div class="modal-content">
              <div class="modal-header">
                  <h5 class="modal-title"><%= gettext("Support %{streamer_username}", streamer_username: @streamer.username) %></h5>
                  <button type="button" class="close" phx-click="hide_modal" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                  </button>
              </div>

              <div class="modal-body">
                  <div class="row">
                      <div class="col-lg-2">
                          <div class="nav nav-pills flex-row flex-lg-column text-center" role="tablist" aria-orientation="vertical">
                              <%= if @can_receive_payments do %>
                              <a phx-click="change_tab" phx-value-tab="subscription" href="#" class={["nav-link text-color", if(@tab == "subscription", do: "active")]}>
                                  <i class="fas fa-star fa-fw fa-2x"></i><br>
                                  <%= gettext("Subscribe") %>
                              </a>
                              <a phx-click="change_tab" phx-value-tab="gift_subscription" href="#" class={["mt-2 nav-link text-color",  if(@tab == "gift_subscription", do: "active")]}>
                              <i class="fas fa-gift fa-fw fa-2x"></i><br>
                              Gift a Sub
                              </a>
                              <a phx-click="change_tab" phx-value-tab="donate" href="#" class={["mt-2 nav-link text-color",  if(@tab == "donate", do: "active")]}>
                                  <i class="fas fa-money-bill-wave fa-fw fa-2x"></i><br>
                                  Donate
                              </a>
                              <% end %>
                              <%= if @channel.streamloots_url do %>
                              <a phx-click="change_tab" phx-value-tab="streamloots" href="#" class={["mt-lg-2 nav-link text-color",  if(@tab == "streamloots", do: "active")]}>
                                  <%= if @site_theme == "light" do %>
                                  <img src="/images/support-modal/streamloots-logo-black.svg" alt="" height="40" width="32">
                                  <% else %>
                                  <img src="/images/support-modal/streamloots-logo.svg" alt="" height="40" width="32">
                                  <% end %>
                                  <br>
                                  Streamloots
                              </a>
                              <% end %>
                          </div>
                      </div>
                      <div class="col-lg-10">
                          <div class="tab-content" id="v-pills-tabContent">
                              <div class="tab-pane fade show active mt-4 mb-4" role="tabpanel">
                                  <%= if @async_success_message do %>
                                  <p class="alert alert-success" role="alert"><%= @async_success_message %></p>
                                  <% end %>

                                  <%= if @tab == "subscription" do %>
                                  <.subscribe_contents socket={@socket} is_the_streamer={@is_the_streamer} streamer={@streamer} user={@user} />
                                  <% end %>

                                  <%= if @tab == "donate" do %>
                                  <.donate_contents socket={@socket} is_the_streamer={@is_the_streamer} user={@user} streamer={@streamer} />
                                  <% end %>

                                  <%= if @tab == "streamloots" do %>
                                  <.streamloots_contents is_the_streamer={@is_the_streamer} streamer={@streamer} />
                                  <% end %>
                              </div>
                          </div>
                      </div>
                  </div>
              </div>
          </div>
      </div>
    </div>
    """
  end

  def subscribe_contents(assigns) do
    ~H"""
    <div class="row">
        <div class="col-sm">
            <h5><%= gettext("Subscribe Monthly!") %></h5>
            <p><%= gettext("Help support %{streamer} monthly by subscribing to their content.", streamer: @streamer.displayname) %></p>

            <ul>
                <li><%= gettext("Support the streamer") %></li>
                <li><%= gettext("Channel sub badge") %></li>
                <li><%= gettext("Site-wide emote usage") %></li>
            </ul>

            <img src="/images/stripe-badge-white.png" alt="We use Stripe as our payment provider." class="img-fluid mt-4 mx-auto d-block">
        </div>
        <div class="col-sm">
            <%= if @is_the_streamer do %>
            <p class="text-center mt-4"><%= gettext("You cannot subscribe to yourself, but others will see a payment dialog here :)!") %></p>
            <% else %>
            <%= live_render(@socket, GlimeshWeb.SupportModal.SubForm, id: "sub-form", session: %{"user" => @user, "streamer" => @streamer}) %>
            <% end %>
        </div>
    </div>
    """
  end

  def donate_contents(assigns) do
    ~H"""
    <div class="row">
      <div class="col-sm">
          <h5><%= gettext("Donate") %></h5>
          <p><%= gettext("Help support %{streamer} by donating to them directly through Glimesh.", streamer: @streamer.displayname) %></p>

          <ul>
            <li><%= gettext("Stripe Fees: 2.9% + 30¢ USD") %></li>
            <li><%= gettext("Glimesh Fees: None") %></li>
            <li><%= gettext("Weekly payouts for streamer") %></li>
          </ul>

          <img src="/images/stripe-badge-white.png" alt="We use Stripe as our payment provider." class="img-fluid mt-4 mx-auto d-block">
      </div>
      <div class="col-sm">
          <%= if @is_the_streamer do %>
          <p class="text-center mt-4"><%= gettext("You cannot donate to yourself, but others will see a donation box here :)!") %></p>
          <% else %>
          <%= live_component(GlimeshWeb.SupportModal.DonateForm, id: "donate-form", user: @user, streamer: @streamer) %>
          <% end %>
      </div>
    </div>
    """
  end

  def streamloots_contents(assigns) do
    ~H"""
    <div class="row justify-content-md-center">
        <div class="col-lg-8">
            <h5><%= gettext("Collect & Redeem Cards!") %></h5>
            <p><%= gettext("Show your support and participate in %{streamer}'s stream with card packs. Get cards, play them and create unique moments live on stream!", streamer: @streamer.displayname) %></p>

            <ul>
                <li><%= gettext("Collect unique cards & earn achievements") %></li>
                <li><%= gettext("Redeem on stream for real-time interaction") %></li>
                <li><%= gettext("Support %{streamer} directly", streamer: @streamer.displayname) %></li>
            </ul>
            <a href={@channel.streamloots_url} class="btn btn-warning btn-lg float-right" target="_blank">Get your packs on <img src="/images/support-modal/streamloots-logo-black.svg" alt="Streamloots" height="32" width="32"></a>
        </div>
    </div>
    """
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply,
     socket
     |> push_patch(to: Routes.user_stream_path(socket, :index, socket.assigns.streamer.username))
     |> assign(:async_success_message, nil)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(:tab, tab)}
  end

  defp default_tab(can_receive_payments, streamloots_url) do
    cond do
      can_receive_payments -> "subscription"
      !is_nil(streamloots_url) -> "streamloots"
      true -> ""
    end
  end

  defp user_input_tab(input, default) do
    if Enum.member?(@valid_tabs, input) do
      input
    else
      default
    end
  end
end
