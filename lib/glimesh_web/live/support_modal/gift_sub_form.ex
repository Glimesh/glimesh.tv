defmodule GlimeshWeb.SupportModal.GiftSubForm do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    assigns = Map.put_new(assigns, :stripe_error, nil)

    ~H"""
    <div>
      <%= if @stripe_error do %>
        <div class="alert alert-danger" role="alert">
          <%= @stripe_error %>
        </div>
      <% end %>

      <%= if @user do %>
        <form id="gift-subscription-form" phx-target={@myself} phx-submit="submit">
          <div class="form-group">
            <label for="recipient"><%= gettext("Recipient") %></label>
            <div class="input-group">
              <%= live_component(GlimeshWeb.Components.UserLookupTypeahead,
                id: "user-lookup",
                user: @user,
                field: "recipient",
                class: "form-control channel-typeahead-input",
                matches: [],
                timeout: 400,
                extra_params: %{"maxlength" => "24"}
              ) %>
            </div>
          </div>

          <div class="text-center my-4">
            <h4>
              Channel Subscription <br />
              <small>
                <strong>$<%= format_price(500) %></strong>
              </small>
            </h4>
          </div>

          <p>
            You will be redirected to our payments provider to complete your gift sub.
          </p>

          <div id="card-errors" role="alert"></div>

          <div class="text-center">
            <div
              class="show-on-loading spinner-border mb-4"
              style="width: 3rem; height: 3rem;"
              role="status"
            >
              <span class="sr-only">Loading...</span>
            </div>
          </div>

          <button type="submit" class="btn btn-primary btn-block btn-lg">
            <%= gettext("Proceed to Checkout") %>
          </button>
        </form>
      <% else %>
        <h4 class="mt-4"><%= gettext("What is Glimesh?") %></h4>
        <p class="">
          <%= gettext(
            "People first streaming, with discoverability as a primary feature. Let's build the next
            generation of streaming."
          ) %>
          <%= link(gettext("Learn More"), to: Routes.about_path(@socket, :faq), target: "_blank") %>
        </p>
        <%= link(gettext("Register"),
          class: "btn btn-primary btn-block mt-4",
          to: Routes.user_registration_path(@socket, :new),
          target: "_blank"
        ) %>
        <p class="mt-2 text-center">
          or <%= link(gettext("Log in"),
            class: "",
            to: Routes.user_session_path(@socket, :new),
            target: "_blank"
          ) %>
        </p>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("submit", %{"recipient" => recipient}, socket) do
    user = socket.assigns.user
    streamer = socket.assigns.streamer

    return_url =
      GlimeshWeb.Router.Helpers.user_stream_url(
        GlimeshWeb.Endpoint,
        :support,
        streamer.username,
        "gift_subscription"
      )

    amount = Glimesh.Payments.get_channel_sub_base_price()

    with %Glimesh.Accounts.User{} = user_to_be_gifted_to <-
           Glimesh.Accounts.get_by_username(recipient),
         {:ok, %Stripe.Session{url: url}} <-
           Glimesh.Payments.start_gift_subscription(
             user,
             streamer,
             user_to_be_gifted_to,
             amount,
             return_url
           ) do
      {:noreply, socket |> redirect(external: url)}
    else
      nil ->
        {:noreply, socket |> assign(stripe_error: "Recipient user not found.")}

      {:validation, message} ->
        {:noreply, socket |> assign(stripe_error: message)}
    end
  end

  def handle_event("change_amount", _, socket) do
    {:noreply, socket}
  end
end
