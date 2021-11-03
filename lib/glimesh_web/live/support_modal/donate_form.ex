defmodule GlimeshWeb.SupportModal.DonateForm do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <h5><%= gettext("Your Payment Information") %></h5>
      <%= if @stripe_error do %>
        <div class="alert alert-danger" role="alert">
          <%= @stripe_error %>
        </div>
      <% end %>

      <form id="donation-form" phx-submit="submit" phx-change="change_amount">
          <div class="form-group">
            <label for="donationAmount"><%= gettext("Amount") %></label>
            <div class="input-group">
              <div class="input-group-prepend">
                <span class="input-group-text">$</span>
              </div>
              <input id="donationAmount" name="amount" type="number" min="1" step="any" value="<%= float_to_binary(@amount) %>"  placeholder="5.00" required class="form-control">
            </div>
          </div>

          <p>Streamer will receive about $<%= float_to_binary(@streamer_amount) %></p>

          <div id="card-errors" role="alert"></div>

          <div class="text-center">
            <div class="show-on-loading spinner-border mb-4" style="width: 3rem; height: 3rem;" role="status">
              <span class="sr-only">Loading...</span>
            </div>
          </div>

          <button type="submit" class="btn btn-primary btn-block btn-lg"><%= gettext("Donate") %></button>
      </form>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:amount, 5.00)
     |> assign(:streamer_amount, calculate_streamer_amount(5.00))
     |> assign(:stripe_public_key, Application.get_env(:stripity_stripe, :public_api_key))
     |> assign(:stripe_customer_id, Accounts.get_stripe_customer_id(user))
     |> assign(:stripe_payment_method, user.stripe_payment_method)
     |> assign(:stripe_error, nil)
     |> assign(:streamer, streamer)
     |> assign(:user, user)}
  end

  def handle_event("submit", %{"amount" => amount}, socket) do
    user = socket.assigns.user
    streamer = socket.assigns.streamer
    return_url = "https://glimesh.dev/clone1018"

    case Float.parse(amount) do
      {amount, _rem} ->
        amount = trunc(amount) * 100

        case Glimesh.Payments.start_channel_donation(user, streamer, amount, return_url) do
          {:ok, %Stripe.Session{url: url}} ->
            {:noreply, socket |> redirect(external: url)}

          {:validation, message} ->
            {:noreply, socket |> assign(:stripe_error, message)}

          _ ->
            {:noreply, socket |> assign(:stripe_error, "Unexpected error")}
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
