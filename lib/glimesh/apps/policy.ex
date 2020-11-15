defmodule Glimesh.Apps.Policy do
  @moduledoc """
  Glimesh Apps Policy

  :show_app -> Should allow admins, or direct owner's to access.
  :create_app -> Should allow anyone to create an app.
  :update_app -> Should allow admins, or direct owner's to access.
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Apps.App

  def authorize(:show_app, %User{is_admin: true}, _app), do: true
  def authorize(:show_app, %User{} = user, %App{} = app), do: user.id == app.user_id

  def authorize(:create_app, %User{}, _nothing), do: true

  def authorize(:update_app, %User{is_admin: true}, _app), do: true
  def authorize(:update_app, %User{} = user, %App{} = app), do: user.id == app.user_id

  def authorize(_, _, _), do: false
end
