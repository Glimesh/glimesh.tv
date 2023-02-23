defmodule GlimeshWeb.Users.PaymentsLive do
  use GlimeshWeb, :user_settings_live_view

  alias Glimesh.Accounts
  alias Glimesh.PaymentProviders.StripeProvider
  alias Glimesh.Payments

  def render(assigns) do
    ~H"""
    <div class="container">
      <h2 class="mt-4"><%= gettext("Your Payment Portal") %></h2>
      <p>
        <%= gettext(
          "Manage your ongoing subscriptions, see your transaction history, and setup your streamer payout information!"
        ) %>
      </p>

      <%= if @can_payments do %>
        <div class="row">
          <div class="col">
            <i class="fas fa-gift float-right"></i>
            <h6 class="mb-0"><%= gettext("Giving Monthly") %></h6>
            <p class="value">$<%= format_price(@sum_outgoing) %></p>
          </div>
          <div class="col">
            <i class="fas fa-wallet float-right"></i>
            <h6 class="mb-0"><%= gettext("Receiving Monthly") %></h6>
            <p class="value">$<%= format_price(@sum_incoming) %></p>
          </div>
          <div class="col">
            <i class="fas fa-gift float-right"></i>
            <h6 class="mb-0"><%= gettext("Active Subscriptions") %></h6>
            <p class="value"><%= @count_outgoing %></p>
          </div>
          <div class="col">
            <i class="fas fa-wallet float-right"></i>
            <h6 class="mb-0"><%= gettext("Active Subscribers") %></h6>
            <p class="value"><%= @count_incoming %></p>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h4>Giving Details</h4>
          </div>
          <div class="card-body">
            <div class="row">
              <div class="col-9">
                <h5><%= gettext("Active Subscriptions") %></h5>

                <table class="table">
                  <thead>
                    <tr>
                      <th>Subscription</th>
                      <th>Monthly Amount</th>
                      <th>Start Date</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= if @platform_subscription do %>
                      <tr>
                        <td><%= @platform_subscription.product_name %> Platform Sub</td>
                        <td>$<%= format_price(@platform_subscription.price) %></td>
                        <td><%= format_datetime(@platform_subscription.started_at) %></td>
                        <td>
                          <%= if @platform_subscription.is_canceling do %>
                            <%= gettext("Canceling on %{date}",
                              date: format_datetime(@platform_subscription.ended_at)
                            ) %>
                          <% else %>
                            <%= link(gettext("Manage Subscription"),
                              to: ~p"/platform_subscriptions",
                              class: ""
                            ) %>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                    <%= for sub <- @subscriptions do %>
                      <tr>
                        <td>
                          <%= if not is_nil(sub.stripe_subscription_id) do %>
                            Channel Sub to
                          <% else %>
                            Gift Sub to
                          <% end %>
                          <%= link(sub.streamer.displayname,
                            to: ~p"/#{sub.streamer.displayname}",
                            class: ""
                          ) %>
                          <%= if not is_nil(sub.from_user_id) do %>
                            <br /> Gifted from <%= sub.from_user.displayname %>
                          <% end %>
                        </td>
                        <td>$<%= format_price(sub.price) %></td>
                        <td><%= format_datetime(sub.started_at) %></td>
                        <td>
                          <%= if sub.is_canceling do %>
                            <%= gettext("Canceling on %{date}", date: format_datetime(sub.ended_at)) %><br />
                          <% end %>
                          <%= link("Manage Subscription",
                            to: ~p"/#{sub.streamer.displayname}",
                            class: ""
                          ) %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
              <div class="col-3">
                <%= if @has_payment_method do %>
                  <h5><%= gettext("Saved Payment Method") %></h5>
                  <p>
                    <%= gettext(
                      "You have an existing saved payment method. You can delete it by clicking the button below."
                    ) %>
                  </p>

                  <.form for={:delete_default_payment} phx-submit="delete_default_payment">
                    <button type="submit" class="btn btn-block btn-danger">
                      <%= gettext("Delete Saved Payment") %>
                    </button>
                  </.form>
                <% else %>
                  <div class="info">
                    <h5 class=""><%= gettext("Setup Payment Method") %></h5>
                  </div>
                  <div class="acc-action">
                    <div class="">
                      <p>
                        <%= gettext(
                          "You can link a payment method by creating a subscription to a channel, or the platform."
                        ) %>
                      </p>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <h5 class="mt-4"><%= gettext("Payment History") %></h5>
            <p>
              <%= gettext(
                "See something you don't expect? Need a refund? Please email us at %{email} and we'll be happy to help!",
                email: "support@glimesh.tv"
              ) %>
            </p>
            <button
              class="btn btn-primary"
              type="button"
              data-toggle="collapse"
              data-target="#fullPaymentHistory"
              aria-expanded="false"
              aria-controls="fullPaymentHistory"
            >
              <%= gettext("Show Full Payment History") %>
            </button>
            <div class="collapse" id="fullPaymentHistory">
              <table class="table">
                <thead>
                  <tr>
                    <th><%= gettext("Date / Time") %></th>
                    <th><%= gettext("Description") %></th>
                    <th><%= gettext("Amount") %></th>
                    <th><%= gettext("Status") %></th>
                  </tr>
                </thead>
                <tbody>
                  <%= for payment <- @payment_history do %>
                    <tr>
                      <td><%= format_datetime(payment.created) %></td>
                      <td><%= payment.description %></td>
                      <td>$<%= format_price(payment.amount) %></td>
                      <td><%= payment.status %></td>
                      <td>
                        <%= unless payment.status == "failed" do %>
                          <a href={payment.receipt_url} target="_blank">Receipt</a>
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="card mt-4">
          <div class="card-header">
            <h4>Receiving Details</h4>
          </div>
          <div class="card-body">
            <div class="row">
              <div class="col-9">
                <h5><%= gettext("Payout History") %></h5>
                <p>
                  <%= gettext(
                    "Please note payouts may take several days to deposit into your bank account. The date shown below is the start of the transfer."
                  ) %>
                </p>
                <table class="table">
                  <thead>
                    <tr>
                      <th>Payout Date</th>
                      <th>Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for payable <- @payable_history do %>
                      <tr>
                        <td><%= format_datetime(payable.streamer_payout_at) %></td>
                        <td>$<%= format_price(payable.streamer_payout_amount) %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
                <%= if @stripe_dashboard_url do %>
                  <a href={@stripe_dashboard_url} class="btn btn-primary" target="_blank">
                    <%= gettext("View payout details on Stripe") %>
                  </a>
                <% else %>
                  <%= gettext("No additional payout information details available.") %>
                <% end %>
              </div>
              <div class="col-3">
                <%= if @user.is_stripe_setup do %>
                  <h5><%= gettext("Glimesh Payouts") %></h5>
                  <%= if @user.is_stripe_setup == false or @user.is_tax_verified == false do %>
                    <p class="text-warning"><%= gettext("Your account setup is still pending.") %></p>
                  <% end %>
                  <ul>
                    <li>
                      <%= gettext("Stripe Setup:") %> <%= truthy_checkbox(@user.is_stripe_setup) %>
                    </li>
                    <li>
                      <%= gettext("Taxes Verified:") %> <%= truthy_checkbox(@user.is_tax_verified) %>
                    </li>
                    <li>
                      <%= gettext("Subscribe Button:") %> <%= truthy_checkbox(@can_receive_payments) %>
                    </li>
                    <li>
                      <%= gettext("Donate Button:") %> <%= truthy_checkbox(@can_receive_payments) %>
                    </li>
                  </ul>
                  <%= unless @user.is_tax_verified do %>
                    <%= link(gettext("Submit Tax Forms"),
                      to: ~p"/users/payments/taxes",
                      class: "btn btn-secondary btn-block mb-2"
                    ) %>
                  <% end %>

                  <%= if @stripe_dashboard_url do %>
                    <a
                      href={@stripe_dashboard_url}
                      class="btn btn-primary btn-block mb-2"
                      target="_blank"
                    >
                      <%= gettext("Manage Stripe Account") %>
                    </a>
                  <% end %>
                  <p>
                    <%= gettext(
                      "If you want to deactivate your account or need help with something, please email support@glimesh.tv"
                    ) %>
                  </p>
                <% else %>
                  <h5><%= gettext("Setup Glimesh Payouts") %></h5>
                  <%= form_for @socket, Routes.user_payments_path(@socket, :setup), fn f -> %>
                    <div class="form-group">
                      <%= label(f, gettext("Your Country")) %>
                      <%= select(f, :country, @stripe_countries, class: "form-control", required: true) %>
                      <small class="form-text text-muted">
                        <%= gettext(
                          "We only support payouts in the countries listed above, if you don't see your country then unfortunately we do not yet support payouts for you."
                        ) %>
                      </small>
                      <%= error_tag(f, :country) %>
                    </div>

                    <%= submit(gettext("Start Process"),
                      class: "btn btn-secondary",
                      "data-confirm":
                        "Are you sure you wish to start the payouts setup with this country? You cannot change your country if you make a mistake."
                    ) %>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <div class="alert alert-primary" role="alert">
          <%= gettext("Your account does not currently have payments enabled.") %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    tokens = Glimesh.Apps.list_valid_tokens_for_user(user)

    countries =
      ["Select Your Country": ""] ++
        StripeProvider.list_payout_countries()

    stripe_dashboard_url = Payments.get_stripe_dashboard_url(user)

    {:ok,
     socket
     |> put_page_title("Payments")
     |> assign(:user, user)
     |> assign(:can_payments, Accounts.can_use_payments?(user))
     |> assign(:can_receive_payments, Accounts.can_receive_payments?(user))
     |> assign(:sum_incoming, Payments.sum_incoming(user))
     |> assign(:sum_outgoing, Payments.sum_outgoing(user))
     |> assign(:count_incoming, Payments.count_incoming(user))
     |> assign(:count_outgoing, Payments.count_outgoing(user))
     |> assign(:payable_history, Payments.list_payables_history(user))
     |> assign(:stripe_countries, countries)
     |> assign(:platform_subscription, Payments.get_platform_subscription(user))
     |> assign(:subscriptions, Payments.get_channel_subscriptions(user))
     |> assign(:has_payment_method, !is_nil(user.stripe_payment_method))
     |> assign(:payment_history, Payments.list_payment_history(user))
     |> assign(:stripe_dashboard_url, stripe_dashboard_url)}
  end

  @impl true
  def handle_event("delete_default_payment", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.set_stripe_default_payment(user, nil) do
      {:ok, _} ->
        socket
        |> put_flash(:info, gettext("Payment method deleted!"))

      {:error, err} ->
        socket
        |> put_flash(:error, err)
    end
  end

  def truthy_checkbox(true) do
    Phoenix.HTML.raw("<i class=\"fas fa-check\"></i>")
  end

  def truthy_checkbox(false) do
    Phoenix.HTML.raw("<i class=\"fas fa-times\"></i>")
  end
end
