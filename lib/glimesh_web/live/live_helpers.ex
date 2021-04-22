defmodule GlimeshWeb.LiveHelpers do
  @moduledoc """
  Inject methods into live views to provide common functionality.
  """

  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `GlimeshWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, GlimeshWeb.PostLive.FormComponent,
        id: @post.id || :new,
        action: @live_action,
        post: @post,
        return_to: Routes.post_index_path(@socket, :index) %>
  """
  def live_modal(_socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)

    modal_opts = [
      id: :modal,
      title: Keyword.fetch!(opts, :title),
      return_to: path,
      component: component,
      opts: opts
    ]

    # Socket param is deprecated from lib author
    live_component(_socket, GlimeshWeb.ModalComponent, modal_opts)
  end
end
