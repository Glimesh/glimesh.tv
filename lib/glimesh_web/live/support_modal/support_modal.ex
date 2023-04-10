defmodule GlimeshWeb.SupportModal do
  use GlimeshWeb, :live_component

  attr :streamer, Glimesh.Accounts.User, required: true
  attr :user, Glimesh.Accounts.User
  attr :tab, :string
  attr :success_message, :string

  def render(assigns) do
    assigns = Map.put(assigns, :is_the_streamer, false)

    ~H"""
    <div>
      <div class="relative z-50">
        <div class="fixed inset-0 bg-slate-700/50 transition-opacity" />
        <div class="fixed inset-0 overflow-y-auto" role="dialog" aria-modal="true" tabindex="0">
          <div class="flex min-h-full items-center justify-center">
            <div class="w-full max-w-3xl">
              <.focus_wrap
                id="support-modal-focus-wrap"
                phx-window-keydown={JS.patch(~p"/#{@streamer.username}")}
                phx-key="escape"
                phx-click-away={JS.patch(~p"/#{@streamer.username}")}
                class="relative rounded-lg bg-gray-800 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
              >
                <div class="absolute top-5 right-5">
                  <button
                    phx-click={JS.patch(~p"/#{@streamer.username}")}
                    type="button"
                    class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                    aria-label={gettext("close")}
                  >
                    <Heroicons.x_mark solid class="h-5 w-5 stroke-current" />
                  </button>
                </div>
                <div>
                  <div class="divide-y divide-slate-700 lg:grid lg:grid-cols-12 lg:divide-y-0 lg:divide-x">
                    <aside
                      class="lg:col-span-3 rounded-tl-lg rounded-bl-lg bg-slate-800/75 space-y-4 py-4"
                      aria-label="Sidebar"
                    >
                      <ul class="">
                        <%= for link <- sidebar_items(@streamer, @tabs) do %>
                          <li>
                            <.link
                              patch={link.to}
                              replace
                              class={[
                                if(link.tab == @tab, do: "bg-slate-700/75"),
                                "flex items-center px-4 p-2 text-base font-normal text-white cursor-pointer hover:bg-slate-700/75"
                              ]}
                            >
                              <%= link.icon.(%{
                                class:
                                  "flex-shrink-0 w-6 h-6 transition duration-75 text-gray-400 group-hover:text-white"
                              }) %>
                              <span class="ml-3"><%= link.label %></span>
                            </.link>
                          </li>
                        <% end %>
                      </ul>
                    </aside>

                    <div class="flex flex-col items-stretch justify-between bg-slate-800/75 lg:col-span-9">
                      <div class="p-4 md:flex md:items-center md:justify-between">
                        <div class="min-w-0 flex-1">
                          <Title.h1>
                            <%= gettext("Support %{streamer_username}",
                              streamer_username: @streamer.username
                            ) %>
                          </Title.h1>
                        </div>
                      </div>

                      <div class="flex-1 bg-slate-800 mt-[-1px] border-t border-slate-700">
                        <div class="p-4">
                          <%= if @success_message do %>
                            <p class="alert alert-success" role="alert">
                              <%= @success_message %>
                            </p>
                          <% end %>

                          <%= if "subscribe" in @tabs and @tab == "subscribe" do %>
                            <.subscribe_contents
                              socket={@socket}
                              is_the_streamer={@is_the_streamer}
                              streamer={@streamer}
                              user={@user}
                            />
                          <% end %>

                          <%= if "gift_subscription" in @tabs and @tab == "gift_subscription" do %>
                            <.gift_subscription_contents
                              socket={@socket}
                              is_the_streamer={@is_the_streamer}
                              streamer={@streamer}
                              user={@user}
                            />
                          <% end %>

                          <%= if "donate" in @tabs and @tab == "donate" do %>
                            <.donate_contents
                              socket={@socket}
                              is_the_streamer={@is_the_streamer}
                              user={@user}
                              streamer={@streamer}
                            />
                          <% end %>

                          <%= if "streamloots" in @tabs and @tab == "streamloots" do %>
                            <.streamloots_contents
                              is_the_streamer={@is_the_streamer}
                              streamer={@streamer}
                              channel={@streamer.channel}
                            />
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </.focus_wrap>
            </div>
          </div>
        </div>
      </div>
    </div>

    <%!--
        <div class="flex">
          <div class="">
            <div class="flex flex-col text-center" role="tablist" aria-orientation="vertical">
              <%= if "subscribe" in @tabs do %>
                <.link
                  patch={~p"/#{@streamer.username}/support?tab=subscribe"}
                  class={["rounded-lg", if(@tab == "subscribe", do: "bg-slate-700")]}
                >
                  <Heroicons.plus class="h-5 w-5 stroke-current" />
                  <br />
                  <%= gettext("Subscribe") %>
                </.link>
              <% end %>
              <.link
                patch={~p"/#{@streamer.username}/support?tab=gift_subscription"}
                class={[
                  "mt-2 nav-link text-color",
                  if(@tab == "gift_subscription", do: "bg-slate-700")
                ]}
              >
                <Heroicons.plus class="h-5 w-5 stroke-current" />
                <br /> Gift a Sub
              </.link>
              <%= if "donate" in @tabs do %>
                <.link
                  patch={~p"/#{@streamer.username}/support?tab=donate"}
                  class={["mt-2 nav-link text-color", if(@tab == "donate", do: "bg-slate-700")]}
                >
                  <Heroicons.plus class="h-5 w-5 stroke-current" />
                  <br /> Donate
                </.link>
              <% end %>
              <%= if "streamloots" in @tabs do %>
                <.link
                  patch={~p"/#{@streamer.username}/support?tab=streamloots"}
                  class={[
                    "mt-lg-2 nav-link text-color",
                    if(@tab == "streamloots", do: "bg-slate-700")
                  ]}
                >
                  <img src="/images/support-modal/streamloots-logo.svg" alt="" height="40" width="32" />
                  <br /> Streamloots
                </.link>
              <% end %>
            </div>
          </div>
          <div class="flex-1">
            <div class="tab-content" id="v-pills-tabContent">
              <div class="tab-pane fade show active mt-4 mb-4" role="tabpanel">
                <%= if @success_message do %>
                  <p class="alert alert-success" role="alert"><%= @success_message %></p>
                <% end %>

                <%= if "subscribe" in @tabs and @tab == "subscribe" do %>
                  <.subscribe_contents
                    socket={@socket}
                    is_the_streamer={@is_the_streamer}
                    streamer={@streamer}
                    user={@user}
                  />
                <% end %>

                <%= if "gift_subscription" in @tabs and @tab == "gift_subscription" do %>
                  <.gift_subscription_contents
                    socket={@socket}
                    is_the_streamer={@is_the_streamer}
                    streamer={@streamer}
                    user={@user}
                  />
                <% end %>

                <%= if "donate" in @tabs and @tab == "donate" do %>
                  <.donate_contents
                    socket={@socket}
                    is_the_streamer={@is_the_streamer}
                    user={@user}
                    streamer={@streamer}
                  />
                <% end %>

                <%= if "streamloots" in @tabs and @tab == "streamloots" do %>
                  <.streamloots_contents
                    is_the_streamer={@is_the_streamer}
                    streamer={@streamer}
                    channel={@channel}
                  />
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </.modal>
    </div> --%>
    """
  end

  defp sidebar_items(streamer, tabs) do
    allowed_tabs = [
      %{
        to: ~p"/#{streamer.username}/support?tab=subscribe",
        tab: "subscribe",
        icon: &Icons.user/1,
        label: gettext("Subscription")
      },
      %{
        to: ~p"/#{streamer.username}/support?tab=gift_subscription",
        tab: "gift_subscription",
        icon: &Icons.user/1,
        label: gettext("Gift Subscription")
      },
      %{
        to: ~p"/#{streamer.username}/support?tab=donate",
        tab: "donate",
        icon: &Icons.user/1,
        label: gettext("Donate")
      },
      %{
        to: ~p"/#{streamer.username}/support?tab=streamloots",
        tab: "streamloots",
        icon: &Icons.user/1,
        label: gettext("Streamloots")
      }
    ]

    Enum.reject(allowed_tabs, fn x -> x.tab not in tabs end)
  end

  def subscribe_contents(assigns) do
    ~H"""
    <div class="row">
      <div class="col-sm">
        <h5><%= gettext("Subscribe Monthly!") %></h5>
        <p>
          <%= gettext("Help support %{streamer} monthly by subscribing to their content.",
            streamer: @streamer.displayname
          ) %>
        </p>

        <ul>
          <li><%= gettext("Support the streamer") %></li>
          <li><%= gettext("Channel sub badge") %></li>
        </ul>

        <img
          src="/images/stripe-badge-white.png"
          alt="We use Stripe as our payment provider."
          class="img-fluid mt-4 mx-auto d-block"
        />
      </div>
      <div class="col-sm">
        <%= if @is_the_streamer do %>
          <p class="text-center mt-4">
            <%= gettext(
              "You cannot subscribe to yourself, but others will see a payment dialog here :)!"
            ) %>
          </p>
        <% else %>
          <%= live_render(@socket, GlimeshWeb.SupportModal.SubForm,
            id: "sub-form",
            session: %{"user" => @user, "streamer" => @streamer}
          ) %>
        <% end %>
      </div>
    </div>
    """
  end

  def gift_subscription_contents(assigns) do
    ~H"""
    <div class="row">
      <div class="col-sm">
        <h5><%= gettext("Gift Subscription") %></h5>
        <p>
          <%= gettext("Help support %{streamer} by gifting a subscription to anyone you choose.",
            streamer: @streamer.displayname
          ) %>
        </p>
        <p>
          <%= gettext(
            "The recipient will immediately receive the benefits of a channel sub and will have the option to continue their sub before the end of the subscription."
          ) %>
        </p>

        <img
          src="/images/stripe-badge-white.png"
          alt="We use Stripe as our payment provider."
          class="img-fluid mt-4 mx-auto d-block"
        />
      </div>
      <div class="col-sm">
        <%= live_component(GlimeshWeb.SupportModal.GiftSubForm,
          id: "gift-subscription-form",
          user: @user,
          streamer: @streamer
        ) %>
      </div>
    </div>
    """
  end

  def donate_contents(assigns) do
    ~H"""
    <div class="row">
      <div class="col-sm">
        <h5><%= gettext("Donate") %></h5>
        <p>
          <%= gettext("Help support %{streamer} by donating to them directly through Glimesh.",
            streamer: @streamer.displayname
          ) %>
        </p>

        <ul>
          <li><%= gettext("Stripe Fees: 2.9% + 30¢ USD") %></li>
          <li><%= gettext("Glimesh Fees: None") %></li>
          <li><%= gettext("Bi-weekly payouts for streamer") %></li>
        </ul>

        <img
          src="/images/stripe-badge-white.png"
          alt="We use Stripe as our payment provider."
          class="img-fluid mt-4 mx-auto d-block"
        />
      </div>
      <div class="col-sm">
        <%= if @is_the_streamer do %>
          <p class="text-center mt-4">
            <%= gettext("You cannot donate to yourself, but others will see a donation box here :)!") %>
          </p>
        <% else %>
          <%= live_component(GlimeshWeb.SupportModal.DonateForm,
            id: "donate-form",
            user: @user,
            streamer: @streamer
          ) %>
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
        <p>
          <%= gettext(
            "Show your support and participate in %{streamer}'s stream with card packs. Get cards, play them and create unique moments live on stream!",
            streamer: @streamer.displayname
          ) %>
        </p>

        <ul>
          <li><%= gettext("Collect unique cards & earn achievements") %></li>
          <li><%= gettext("Redeem on stream for real-time interaction") %></li>
          <li><%= gettext("Support %{streamer} directly", streamer: @streamer.displayname) %></li>
        </ul>
        <a href={@channel.streamloots_url} class="btn btn-warning btn-lg float-right" target="_blank">
          Get your packs on
          <img
            src="/images/support-modal/streamloots-logo-black.svg"
            alt="Streamloots"
            height="32"
            width="32"
          />
        </a>
      </div>
    </div>
    """
  end
end
