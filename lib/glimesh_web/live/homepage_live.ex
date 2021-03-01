defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts

  @impl true
  def mount(params, session, socket) do
    maybe_user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    # 2021, 2, 2, 16, 0, 0, 0
    diff = NaiveDateTime.diff(~N[2021-03-02 16:00:00], NaiveDateTime.utc_now(), :millisecond)
    days = Float.floor(diff / (1000 * 60 * 60 * 24)) |> format_num
    hours = Float.floor(rem(diff, 1000 * 60 * 60 * 24) / (1000 * 60 * 60)) |> format_num
    minutes = Float.floor(rem(diff, 1000 * 60 * 60) / (1000 * 60)) |> format_num
    seconds = Float.floor(rem(diff, 1000 * 60) / 1000) |> format_num

    show_prelaunch_stream =
      if NaiveDateTime.diff(~N[2021-03-02 14:50:00], NaiveDateTime.utc_now(), :millisecond) < 0,
        do: true,
        else: Map.has_key?(params, "preview")

    {:ok,
     socket
     |> put_page_title()
     |> assign(:days, days)
     |> assign(:hours, hours)
     |> assign(:minutes, minutes)
     |> assign(:seconds, seconds)
     |> assign(:show_prelaunch_stream, show_prelaunch_stream)
     |> assign(:current_user, maybe_user)}
  end

  defp format_num(input) do
    input
    |> trunc()
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end
end
