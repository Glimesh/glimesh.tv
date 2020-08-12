defmodule GlimeshWeb.UserLive.Components.ReportButton do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~L"""
      <%= if @user do %>
      <div class="text-center">
        <a href="#" phx-click="show_modal" class="text-danger">
          <%= dgettext("profile", "Report User") %> <i class="fas fa-flag"></i>
        </a>
      </div>
      <%= if live_flash(@flash, :info) do %>
      <p class="alert alert-info" role="alert"
          phx-click="lv:clear-flash"
          phx-value-key="info"><%= live_flash(@flash, :info) %></p>
      <% end %>

      <%= if @show_report do %>
       <div id="reportModal" class="live-modal"
            phx-capture-click="hide_modal"
            phx-window-keydown="hide_modal"
            phx-key="escape"
            phx-target="#paymentModal2"
            phx-page-loading>
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Report User</h5>
                        <button type="button" class="close" phx-click="hide_modal" aria-label="Close">
                          <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body">
                      <p><%= dgettext("report", "What has this user done wrong?")%></p>

                      <%= form_for :user, "#", [phx_submit: :save] %>
                      <div class="form-check">
                        <input class="form-check-input" type="radio" name="report_reason" id="hateSpeech" value="hate-speech">
                        <label class="form-check-label" for="exampleRadios1">
                          <%= dgettext("report", "Hate Speech") %>
                        </label>
                      </div>
                      <div class="form-check">
                        <input class="form-check-input" type="radio" name="report_reason" id="reportInappropriateContent" value="inappropriate-content">
                        <label class="form-check-label" for="exampleRadios2">
                          <%= dgettext("report", "Inappropriate Content") %>
                        </label>
                      </div>
                      <div class="form-check">
                        <input class="form-check-input" type="radio" name="report_reason" id="reportCopyrightInfringementOrLawViolation" value="copyright-infringement-or-law-violation">
                        <label class="form-check-label" for="reportCopyrightInfringementOrLawViolation">
                          <%= dgettext("report", "Copyright Infringement / Law Violation") %>
                        </label>
                      </div>
                      <div class="form-check">
                        <input class="form-check-input" type="radio" name="report_reason" id="reportOther" value="other">
                        <label class="form-check-label" for="reportOther">
                          <%= dgettext("report", "Other") %>
                        </label>
                      </div>

                      <div class="form-group mt-4">
                        <label for="reportNotes"><%= dgettext("report", "Notes") %></label>
                        <input type="text" class="form-control" name="notes" id="reportNotes" placeholder="Another other details you'd like to share">
                      </div>

                      <button class="btn btn-danger btn-block mt-4"><%= dgettext("report", "Submit Report") %></button>
                      </form>
                    </div>


                </div>
            </div>
        </div>
      <% end %>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)
     |> assign(:show_report, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    Gettext.put_locale(user.locale)
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:show_report, false)}
  end

  @impl true
  @spec handle_event(<<_::32, _::_*48>>, any, Phoenix.LiveView.Socket.t()) :: {:noreply, map}
  def handle_event("save", %{"report_reason" => report_reason, "notes" => notes}, socket) do
    {:ok, _} =
      Glimesh.Accounts.UserNotifier.deliver_user_report_alert(
        socket.assigns.user,
        socket.assigns.streamer,
        report_reason,
        notes
      )

    {:noreply,
     socket |> assign(:show_report, false) |> put_flash(:info, "Report submitted, thank you!")}
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_report, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_report, false)}
  end
end
