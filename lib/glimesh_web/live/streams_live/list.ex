defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams
  alias Glimesh.ChannelLookups
  alias Glimesh.ChannelCategories

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    case Accounts.get_user_by_session_token(session["user_token"]) do
      %Glimesh.Accounts.User{} = user ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        channels = ChannelLookups.list_live_followed_channels(user)

        {:ok,
         socket
         |> put_page_title(gettext("Followed Streams"))
         |> assign(:tags, nil)
         |> assign(:list_name, "Followed")
         |> assign(:channels, channels)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case ChannelCategories.get_category(params["category"]) do
      %Streams.Category{} = category ->
        tags = ChannelCategories.list_live_tags(category.id)

        {:ok,
         socket
         |> put_page_title(category.name)
         |> assign(:list_name, category.name)
         |> assign(:tags, tags)
         |> assign(:tag_selected, Map.has_key?(params, "tag"))
         |> assign(:category, category)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    channels = ChannelLookups.filter_live_channels(Map.take(params, ["category", "tag"]))

    {:noreply,
     socket
     |> assign(:tag_selected, Map.has_key?(params, "tag"))
     |> assign(:channels, channels)}
  end
end
