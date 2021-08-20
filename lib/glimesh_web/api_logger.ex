defmodule GlimeshWeb.ApiLogger do
  @moduledoc """
  Glimesh API Logger
  """
  require Logger

  def start_logger do
    :telemetry.attach(
      "absinthe-query-logger",
      [:absinthe, :execute, :operation, :start],
      &GlimeshWeb.ApiLogger.log_query/4,
      nil
    )
  end

  def log_query(_event, _time, %{blueprint: %{input: raw_query}, options: options}, _)
      when is_binary(raw_query) do
    case options do
      %{context: context} ->
        access =
          Keyword.get(context, :access, %{
            access_type: "Unknown",
            access_identifier: "Unknown"
          })

        Logger.info(
          "[Absinthe Operation] Access Type: #{access.access_type} Access Identifier: #{access.access_identifier} Query: #{inspect(raw_query)} "
        )

      _ ->
        nil
    end
  end
end
