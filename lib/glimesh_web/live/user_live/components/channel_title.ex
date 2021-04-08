defmodule GlimeshWeb.UserLive.Components.ChannelTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <!-- Mobile -->
    <div class="d-block d-sm-none">
      <p class="mb-0">
        <span class="badge badge-primary"><%= @channel.category.name %></span> <%= @channel.title %>
      </p>
    </div>
    <!-- Anything else -->
    <div class="d-none d-sm-block">
    <h5 class="mb-0">
      <%= render_badge(@channel) %> <span class="badge badge-primary"><%= @channel.category.name %></span> <%= @channel.title %>
      <%= if @can_change do %>
      <a class="fas fa-edit" phx-click="toggle-edit" href="#" aria-label="<%= gettext("Edit") %>"></a>
      <% end %>
    </h5>
    <%= if @channel.subcategory do %>
    <%= live_patch @channel.subcategory.name, to: Routes.streams_list_path(@socket, :index, @channel.category.slug, subcategory: [@channel.subcategory.slug]), class: "badge badge-pill badge-info" %>
    <% end %>
    <%= for tag <- @channel.tags do %>
      <%= live_patch tag.name, to: Routes.streams_list_path(@socket, :index, @channel.category.slug, tags: [tag.slug]), class: "badge badge-pill badge-primary" %>
    <% end %>
    </div>

    <%= if @editing do %>
        <div id="channelEditor" class="live-modal"
            phx-capture-click="toggle-edit"
            phx-window-keydown="toggle-edit"
            phx-key="escape"
            phx-target="#channelEditor"
            phx-page-loading>
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title"><%= gettext("Stream Info") %></h5>
                        <button type="button" class="close" phx-click="toggle-edit" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body">
                      <%= f = form_for @changeset, "#", [phx_submit: :save, phx_change: :change_channel] %>
                          <div class="form-group">
                              <%= label f, :title, gettext("Title") %>
                              <%= text_input f, :title, [class: "form-control", phx_update: "ignore"] %>
                              <%= error_tag f, :title %>
                          </div>
                          <div class="form-group">
                              <%= label f, :category_id, gettext("Category") %>
                              <%= select f, :category_id, @categories, [class: "form-control"] %>
                              <%= error_tag f, :category_id %>
                          </div>
                          <div class="form-group">
                            <%= label f, :subcategory, @subcategory_label %>
                            <%= live_component(
                                @socket,
                                GlimeshWeb.TagifyComponent,
                                id: "category-selector",
                                form: f, field: :subcategory,
                                max_options: 1,
                                allow_edit: "true",
                                create_regex: "^[A-Za-z0-9: -]{2,40}$",
                                value: @existing_subcategory,
                                placeholder: @subcategory_placeholder,
                                category: @category,
                                search_func: &search_categories/2
                            )
                            %>
                            <p><%= @subcategory_attribution %></p>
                            <%= error_tag f, :subcategory %>
                          </div>
                          <div class="form-group">
                              <%= label f, :tags, gettext("Tags") %>
                              <%= live_component(
                                  @socket,
                                  GlimeshWeb.TagifyComponent,
                                  id: "tag-selector",
                                  form: f, field: :tags,
                                  value: @existing_tags,
                                  placeholder: gettext("Search for tags to describe your stream"),
                                  max_options: 10,
                                  allow_edit: "true",
                                  create_regex: "^[A-Za-z0-9: -]{2,18}$",
                                  category: @category,
                                  search_func: &search_tags/2
                              )
                              %>
                              <%= error_tag f, :tags %>
                          </div>

                          <button type="submit" class="btn btn-primary btn-block btn-lg"><%= gettext("Save") %></button>

                      </form>
                    </div>
                </div>
            </div>
        </div>
    <% end %>
    """
  end

  def render_badge(channel) do
    if channel.status == "live" do
      raw("""
      <span class="badge badge-danger">Live!</span>
      """)
    else
      raw("")
    end
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:user, nil)
     |> assign(:channel, channel)
     |> assign(:editing, false)
     |> assign(:can_change, false)}
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)

    {:ok,
     socket
     |> assign_categories()
     |> assign_subcategory(channel.category)
     |> assign_existing_tags(channel)
     |> assign(:channel, channel)
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))
     |> assign(:current_category_id, channel.category_id)
     |> assign(:category, channel.category)
     |> assign(:can_change, Bodyguard.permit?(Glimesh.Streams, :update_channel, user, channel))
     |> assign(:editing, false)}
  end

  def search_categories(query, socket) do
    ChannelCategories.tagify_search_for_subcategories(socket.assigns.category, query)
  end

  def search_tags(query, socket) do
    ChannelCategories.tagify_search_for_tags(socket.assigns.category, query)
  end

  @impl true
  def handle_event("toggle-edit", _value, socket) do
    {:noreply, socket |> assign(:editing, !socket.assigns.editing)}
  end

  @impl true
  def handle_event(
        "change_channel",
        %{"_target" => ["channel", "category_id"], "channel" => channel},
        socket
      ) do
    category = ChannelCategories.get_category_by_id!(channel["category_id"])

    {:noreply,
     socket
     |> assign_subcategory(category)
     |> assign(:existing_subcategory, "")
     |> assign(:existing_tags, "")
     |> assign(:category, category)
     |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"channel" => channel}, socket) do
    case Streams.update_channel(socket.assigns.user, socket.assigns.channel, channel) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign_subcategory(channel.category)
         |> assign_existing_tags(channel)
         |> assign(:editing, false)
         |> assign(:channel, channel)
         |> assign(:changeset, Streams.change_channel(channel))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:channel, channel}, socket) do
    {:noreply,
     socket
     |> assign_subcategory(channel.category)
     |> assign_existing_tags(channel)
     |> assign(:editing, false)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))}
  end

  defp assign_subcategory(socket, category) do
    socket
    |> assign(
      :subcategory_label,
      ChannelCategories.get_subcategory_label(category)
    )
    |> assign(
      :subcategory_placeholder,
      ChannelCategories.get_subcategory_select_label_description(category)
    )
    |> assign(
      :subcategory_attribution,
      Glimesh.ChannelCategories.get_subcategory_attribution(category)
    )
  end

  defp assign_existing_tags(socket, channel) do
    socket
    |> assign(
      :existing_subcategory,
      if(channel.subcategory, do: channel.subcategory.name, else: "")
    )
    |> assign(:existing_tags, Enum.map(channel.tags, fn tag -> tag.name end) |> Enum.join(", "))
  end

  defp assign_categories(socket) do
    socket
    |> assign(
      :categories,
      ChannelCategories.list_categories_for_select()
    )
  end
end
