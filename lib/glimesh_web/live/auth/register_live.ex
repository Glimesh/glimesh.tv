defmodule GlimeshWeb.Auth.RegisterLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex items-stretch justify-between">
      <div class="flex-1"></div>
      <div class="w-1/2 p-6 bg-slate-800/75">
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
              Sign in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          class="w-96 mx-auto h-full"
          method="post"
        >
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input field={@form[:username]} type="text" label="Username" required autofocus />
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />
          <.input
            field={@form[:allow_glimesh_newsletter_emails]}
            type="checkbox"
            label="Allow Glimesh Newsletter Emails"
          />
          <p>We'll send emails about product launches, upcoming events, or new availability.</p>

          <script src="https://js.hcaptcha.com/1/api.js" async defer>
          </script>
          <div
            id="hcaptcha"
            phx-update="ignore"
            class="h-captcha"
            data-sitekey="10000000-ffff-ffff-ffff-000000000001"
          >
          </div>

          <:actions>
            <.button phx-disable-with="Creating account...">Create an account</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event(
        "save",
        %{"user" => user_params, "h-captcha-response" => captcha_response},
        socket
      ) do
    with {:ok, _} <- verify_captcha(captcha_response),
         {:ok, user} <- Accounts.register_user(user_params) do
      {:ok, _} =
        Accounts.deliver_user_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )

      changeset = Accounts.change_user_registration(user)
      {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp verify_captcha(captcha_response) do
    case HTTPoison.post(
           "https://hcaptcha.com/siteverify",
           URI.encode_query(%{
             "response" => captcha_response,
             "sitekey" => Application.get_env(:hcaptcha, :public_key),
             "secret" => Application.get_env(:hcaptcha, :secret)
           }),
           %{"Content-Type" => "application/x-www-form-urlencoded"}
         ) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Jason.decode(body)
    end
  end
end
