defmodule GlimeshWeb.SupportModal.DonateForm do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    assigns = Map.put_new(assigns, :stripe_error, nil)
    assigns = Map.put_new(assigns, :amount, 5.00)
    assigns = Map.put_new(assigns, :streamer_amount, calculate_streamer_amount(5.00))

    ~H"""
    <div>
      <%= if @stripe_error do %>
        <div class="alert alert-danger" role="alert">
          <%= @stripe_error %>
        </div>
      <% end %>

      <%= if @user do %>
        <form id="donation-form" phx-target={@myself} phx-submit="submit" phx-change="change_amount">
          <div class="form-group">
            <label for="donationAmount"><%= gettext("Amount") %></label>
            <div class="input-group">
              <div class="input-group-prepend">
                <span class="input-group-text">$</span>
              </div>
              <input
                id="donationAmount"
                name="amount"
                type="number"
                min="1"
                max="100"
                step="any"
                value={float_to_binary(@amount)}
                placeholder="5.00"
                required
                autofocus
                class="form-control"
              />
            </div>
          </div>

          <p>
            The streamer will receive about $<%= float_to_binary(@streamer_amount) %>
            after processing fees.
          </p>

          <p>You will be redirected to our payments provider Stripe to complete your donation.</p>

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
          or
          <%= link(gettext("Log in"),
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
  def handle_event("submit", %{"amount" => amount}, socket) do
    user = socket.assigns.user
    streamer = socket.assigns.streamer

    return_url =
      GlimeshWeb.Router.Helpers.user_stream_url(
        GlimeshWeb.Endpoint,
        :support,
        streamer.username,
        "donate"
      )

    case Float.parse(amount) do
      {amount, _rem} ->
        amount = trunc(amount * 100)

        case Glimesh.Payments.start_channel_donation(user, streamer, amount, return_url) do
          {:ok, %Stripe.Session{url: url}} ->
            {:noreply, socket |> redirect(external: url)}

          {:validation, message} ->
            {:noreply, socket |> assign(:stripe_error, message)}
        end

      _ ->
        {:noreply, socket |> assign(:stripe_error, "Problem parsing the amount entered")}
    end
  end

  @impl true
  def handle_event("change_amount", %{"amount" => amount}, socket) when is_binary(amount) do
    streamer_amount =
      case Float.parse(amount) do
        {amount, _rem} ->
          calculate_streamer_amount(amount)

        _ ->
          0.00
      end

    {:noreply, socket |> assign(:streamer_amount, streamer_amount)}
  end

  def handle_event("change_amount", _, socket) do
    {:noreply, socket}
  end

  defp calculate_streamer_amount(amount) when is_float(amount) do
    Float.floor(amount - amount * 0.029 - 0.30, 2)
  end

  defp float_to_binary(amount) when is_float(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end
end
