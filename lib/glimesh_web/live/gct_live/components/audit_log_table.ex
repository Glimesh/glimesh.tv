defmodule GlimeshWeb.GctLive.Components.AuditLogTable do
  use GlimeshWeb, :live_view

  alias Glimesh.CommunityTeam

  @impl true
  def mount(_params, _session, socket) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      if connected?(socket) do
        CommunityTeam.list_all_audit_entries()
      else
        %Scrivener.Page{}
      end

    assigns = [
      conn: socket,
      audit_log: entries,
      page_number: page_number || 0,
      page_size: page_size || 0,
      total_entries: total_entries || 0,
      total_pages: total_pages || 0,
      verbose: false,
      show_details: false,
      detailed_log: %{id: 0, action: "None", target: "None", more_details: "None"}
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, assign(socket, get_and_assign_page(page, socket.assigns.verbose))}
  end

  @impl true
  def handle_event("show-verbose", _params, socket) do
    {:noreply, socket |> assign(get_and_assign_page(1, true)) |> assign(:verbose, true)}
  end

  @impl true
  def handle_event("hide-verbose", _params, socket) do
    {:noreply, socket |> assign(get_and_assign_page(1, false)) |> assign(:verbose, false)}
  end

  @impl true
  def handle_event("show-details", %{"log-id" => log_id}, socket) do
    {:noreply, socket |> assign(:show_details, true) |> assign(:detailed_log, CommunityTeam.get_audit_log_entry_from_id!(log_id))}
  end

  @impl true
  def handle_event("hide_details_modal", _params, socket) do
    {:noreply, socket |> assign(:show_details, false)}
  end

  def get_and_assign_page(page_number, verbose \\ false) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = CommunityTeam.list_all_audit_entries(verbose, page: page_number)

    [
      audit_log: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end
end
