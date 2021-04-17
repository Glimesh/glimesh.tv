defmodule GlimeshWeb.SupportModal do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Payments

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:streamer, streamer)
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    subscription = Glimesh.Payments.get_channel_subscription(user, streamer)

    can_subscribe = if Accounts.can_use_payments?(user), do: user.id != streamer.id, else: false
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:tab, "subscription")
     |> assign(:streamer, streamer)
     |> assign(:user, user)}
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(:tab, tab)}
  end

  defp render_tab_content("subscription", socket) do
    ""
  end

  defp render_tab_content("gift_subscription", socket) do
    assigns = socket.assigns

    ~L"""
    I'm a gift sub
    """
  end
end
