defmodule Glimesh.Streams.Organizer do
  @moduledoc """
  Organizes a list of channels into a viewable format.
  """

  defmodule Block do
    defstruct [:type, :title, :channels, :all_channels, :background_image_url]
  end

  @spec organize(list, list) :: [%Glimesh.Streams.Organizer.Block{}, ...]
  def organize(list_of_channels, options \\ []) when is_list(list_of_channels) do
    limit = Keyword.get(options, :limit, 120)

    list_of_channels
    |> group_by(Keyword.get(options, :group_by))
    |> limit_channels(limit)
    |> sort_channels()
  end

  defp group_by(channels, nil) do
    [
      produce_block({nil, channels})
    ]
  end

  defp group_by(channels, key) do
    Enum.group_by(channels, fn x -> Map.get(x, key) end)
    |> Enum.map(&produce_block/1)
  end

  defp limit_channels(blocks, limit) when length(blocks) > 1 do
    Enum.map(blocks, fn b ->
      if length(b.channels) > limit do
        %Block{b | channels: Enum.take(b.channels, limit), all_channels: b.channels}
      else
        %Block{b | all_channels: []}
      end
    end)
  end

  defp limit_channels(blocks, _limit) do
    blocks
  end

  defp sort_channels(blocks) do
    Enum.sort(blocks, fn a, b ->
      a.title < b.title
    end)
  end

  defp produce_block({nil, channels}) do
    %Block{
      type: "row",
      title: nil,
      channels: channels,
      all_channels: []
    }
  end

  defp produce_block({%Glimesh.Streams.Subcategory{} = subcategory, channels}) do
    %Block{
      type: "row",
      title: subcategory.name,
      channels: channels,
      all_channels: [],
      background_image_url: subcategory.background_image
    }
  end

  defp produce_block({%Glimesh.Streams.Tag{} = tag, channels}) do
    %Block{
      type: "row",
      title: tag.name,
      channels: channels,
      all_channels: []
    }
  end
end
