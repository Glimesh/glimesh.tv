defmodule GlimeshWeb.Components.Notifications do
  use GlimeshWeb, :live_view

  alias Phoenix.LiveView.JS

  def mount(params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Glimesh.PubSub, "notifications")
      :timer.send_interval(1000, self(), :tick)
      # Process.send_after(self(), :tick, 2000)
    end

    {:ok,
     socket
     |> assign(:ring_bell, true)
     |> assign(:inc, 1)
     |> stream(:notifications, []), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="group inline-block relative">
      <button
        id="notifications-button"
        phx-click={toggle_notifications()}
        type="button"
        class="p-2 rounded-lg rounded-b-none transform ease-out duration-200 transition"
      >
        <span class="sr-only">View notifications</span>
        <!-- Heroicon name: outline/bell -->
        <svg
          class={["h-6 w-6", if(@ring_bell, do: "animate-swing origin-top text-amber-300")]}
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"
          />
        </svg>
      </button>

      <div
        id="notifications-list"
        class="w-72 absolute right-0 rounded-lg rounded-tr-none bg-gray-700 z-10 pt-1 hidden"
      >
        <div :for={i <- 1..1}>
          <div class="p-4">
            <div class="flex items-start">
              <div class="flex-shrink-0">
                <Heroicons.video_camera class="h-6 w-6" />
              </div>
              <div class="ml-3 w-0 flex-1 pt-0.5">
                <p class="text-sm font-medium">clone1018 is live!</p>
                <p class="mt-1 text-sm">
                  Streaming "World of Warcraft" in the Gaming category.
                </p>
                <div class="mt-3 flex space-x-7">
                  <.button size="sm">Watch Channel</.button>
                </div>
              </div>
              <div class="ml-4 flex flex-shrink-0">
                <button
                  type="button"
                  class="inline-flex text-gray-300 hover:text-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                >
                  <span class="sr-only">Close</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def toggle_notifications(js \\ %JS{}) do
    js
    |> JS.remove_class(
      "bg-gray-700",
      to: "#notifications-button.bg-gray-700"
    )
    |> JS.add_class(
      "bg-gray-700",
      to: "#notifications-button:not(.bg-gray-700)"
    )
    |> JS.toggle(
      to: "#notifications-list",
      in:
        {"transform ease-out duration-200 transition", "translate-y-0 opacity-0",
         "translate-y-0 opacity-100"},
      out:
        {"transform ease-out duration-200 transition", "translate-y-0 opacity-100",
         "translate-y-0 opacity-0"},
      time: 200
    )
    |> JS.push("checked_notifications")
  end

  def handle_event("checked_notifications", _, socket) do
    {:noreply, socket |> assign(:ring_bell, false)}
  end

  def old_design(assigns) do
    ~H"""
    <!-- Global notification live region, render this permanently at the end of the document -->
    <div
      aria-live="assertive"
      class="pointer-events-none fixed inset-0 flex items-end px-6 pb-6 pt-20 sm:items-start z-20"
    >
      <div
        id="notifications-overlay"
        phx-update="stream"
        class="flex w-full flex-col items-center space-y-4 sm:items-end"
      >
        <!--
      Notification panel, dynamically insert this into the live region when it needs to be displayed

      Entering: "transform ease-out duration-300 transition"
        From: "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
        To: "translate-y-0 opacity-100 sm:translate-x-0"
      Leaving: "transition ease-in duration-100"
        From: "opacity-100"
        To: "opacity-0"
    -->
        <div
          :for={{dom_id, notification} <- @streams.notifications}
          id={dom_id}
          phx-remove={remove_notification()}
          class="pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5"
        >
          <div class="p-4">
            <div class="flex items-start">
              <div class="flex-shrink-0">
                <svg
                  class="h-6 w-6 text-green-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <div class="ml-3 w-0 flex-1 pt-0.5">
                <p class="text-sm font-medium text-gray-900">Some Notification!</p>
                <p class="mt-1 text-sm text-gray-500">
                  <%= notification.message %> from <%= dom_id %>
                </p>
              </div>
              <div class="ml-4 flex flex-shrink-0">
                <button
                  type="button"
                  class="inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                >
                  <span class="sr-only">Close</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_info({:notification, message}, socket) do
    dbg(message)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    random_id = :rand.uniform(10000)
    Process.send_after(self(), {:untick, random_id}, 6000)

    {:noreply,
     socket
     |> assign(:inc, socket.assigns.inc + 1)
     |> stream_insert(:notifications, %{id: random_id, message: "Hello world"})}
  end

  def handle_info({:untick, id}, socket) do
    {:noreply,
     socket
     |> stream_delete(:notifications, %{id: id, message: "Hello world"})}
  end

  # def toggle_sidebar(js \\ %JS{}) do
  #   js
  #   |> JS.toggle(to: "#notifications-sidebar", time: 700)
  #   |> JS.toggle(
  #     to: "#notifications-sidebar-transition",
  #     in:
  #       {"transform transition ease-in-out duration-500 sm:duration-700", "translate-y-full",
  #        "translate-y-0"},
  #     out:
  #       {"transform transition ease-in-out duration-500 sm:duration-700", "translate-y-0",
  #        "translate-y-full"},
  #     time: 500
  #   )
  # end

  def show_notification(js \\ %JS{}) do
    # Notification panel, dynamically insert this into the live region when it needs to be displayed

    #   Entering: "transform ease-out duration-300 transition"
    #     From: "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
    #     To: "translate-y-0 opacity-100 sm:translate-x-0"
    #   Leaving: "transition ease-in duration-100"
    #     From: "opacity-100"
    #     To: "opacity-0"
    js
    |> JS.hide(
      transition:
        {"transform ease-out duration-300 transition",
         "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2",
         "translate-y-0 opacity-100 sm:translate-x-0"}
    )
  end

  def remove_notification(js \\ %JS{}) do
    # Notification panel, dynamically insert this into the live region when it needs to be displayed

    #   Entering: "transform ease-out duration-300 transition"
    #     From: "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
    #     To: "translate-y-0 opacity-100 sm:translate-x-0"
    #   Leaving: "transition ease-in duration-100"
    #     From: "opacity-100"
    #     To: "opacity-0"
    js
    |> JS.hide(transition: {"transition ease-in duration-300", "opacity-100", "opacity-0"})
  end
end
