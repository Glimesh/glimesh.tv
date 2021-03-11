defmodule GlimeshWeb.GctLive.Components.ChannelChatLogTable do
  use GlimeshWeb, :live_view

  alias Glimesh.Chat
  alias Glimesh.CommunityTeam

  @impl true
  def mount(_params, %{"channel" => channel, "admin" => admin}, socket) do
    Gettext.put_locale(Glimesh.Accounts.get_user_locale(admin))

    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      if connected?(socket) do
        CommunityTeam.paginate_chat_message(Chat.list_all_chat_messages(channel))
      else
        %Scrivener.Page{}
      end

    assigns = [
      conn: socket,
      channel: channel,
      chat_log: entries,
      page_number: page_number || 0,
      page_size: page_size || 0,
      total_entries: total_entries || 0,
      total_pages: total_pages || 0
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, assign(socket, get_and_assign_page(page, socket.assigns.channel))}
  end

  def get_and_assign_page(page_number, channel) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      CommunityTeam.paginate_chat_message(Chat.list_all_chat_messages(channel), page: page_number)

    [
      chat_log: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end
end
