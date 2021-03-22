defmodule Glimesh.Subcategories.RawgSource do
  @moduledoc """
  Pull a list of games from Rawg to pre-fill our subcategory list for gaming.
  """

  @source_name "rawg"

  def update_game_list() do
    {:ok, games} = list_games()

    # Enum.map(games, fn x -> create_subcategory_for_game(x, gaming_id) end)
  end

  def create_subcategory_for_game(game, gaming_category_id) do
    case Glimesh.ChannelCategories.upsert_subcategory_from_source(
           @source_name,
           Integer.to_string(game["id"]),
           %{
             name: game["name"],
             slug: game["slug"],
             user_created: false,
             category_id: gaming_category_id,
             background_image: background_image(game)
           }
         ) do
      {:ok, _game} ->
        IO.puts("Loaded: " <> game["name"])

      {:error, _} ->
        IO.puts("Failed to Load: " <> game["name"])
    end
  end

  defp background_image(%{"background_image" => image, "esrb_rating" => esrb_rating}) do
    if Map.get(esrb_rating, "slug", nil) == "adults-only" do
      ""
    else
      image
    end
  end

  defp background_image(_) do
    ""
  end

  @spec list_games :: {:error, list} | {:ok, list}
  def list_games do
    params =
      URI.encode_query(%{
        "key" => api_key(),
        "page_size" => "40",
        "ordering" => "-metacritic"
      })

    aggregate_page("https://api.rawg.io/api/games?#{params}", [])
  end

  @spec aggregate_page(binary, list) :: {:error, list} | {:ok, list}
  def aggregate_page(next_url, existing_list) do
    %{id: gaming_id} = Glimesh.ChannelCategories.get_category("gaming")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(next_url, [
             {"Content-Type", "application/json"}
           ]),
         {:ok, %{"next" => next, "results" => games}} <- Jason.decode(body) do
      existing_list = existing_list ++ games

      if not is_nil(next) and length(existing_list) < 10000 do
        Enum.map(games, fn x -> create_subcategory_for_game(x, gaming_id) end)

        aggregate_page(next, existing_list)
      else
        {:ok, existing_list}
      end
    else
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, existing_list}

      _ ->
        {:error, existing_list}
    end
  end

  defp api_key() do
    Application.get_env(:glimesh, Glimesh.Subcategories.RawgSource)[:api_key]
  end
end
