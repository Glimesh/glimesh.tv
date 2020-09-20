defmodule Glimesh.OauthHandler.OauthError do
  @moduledoc false

  def add_error({:error, params}, _), do: {:error, params}

  def add_error({:ok, params}, {:error, error, status}) do
    {:error, Map.merge(params, %{error: error, error_status: status})}
  end

  def not_accessable do
    {:error, %{error: :not_accessable}, :not_accessable}
  end

  def invalid_ownership do
    {:error, %{error: :invalid_ownership}, :invalid_ownership}
  end
end
