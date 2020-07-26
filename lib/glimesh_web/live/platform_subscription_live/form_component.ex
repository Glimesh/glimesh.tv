defmodule GlimeshWeb.PlatformSubscriptionLive.FormComponent do
  use GlimeshWeb, :live_component

  alias Glimesh.Payments

  @impl true
  def update(%{platform_subscription: platform_subscription} = assigns, socket) do
    changeset = Payments.change_platform_subscription(platform_subscription)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"platform_subscription" => platform_subscription_params}, socket) do
    changeset =
      socket.assigns.platform_subscription
      |> Payments.change_platform_subscription(platform_subscription_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"platform_subscription" => platform_subscription_params}, socket) do
    save_platform_subscription(socket, socket.assigns.action, platform_subscription_params)
  end

  defp save_platform_subscription(socket, :edit, platform_subscription_params) do
    case Payments.update_platform_subscription(socket.assigns.platform_subscription, platform_subscription_params) do
      {:ok, _platform_subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Platform subscription updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_platform_subscription(socket, :new, platform_subscription_params) do
    case Payments.create_platform_subscription(platform_subscription_params) do
      {:ok, _platform_subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Platform subscription created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
