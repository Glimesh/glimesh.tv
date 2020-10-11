defmodule Glimesh.StreamLayout.PageSection do
  @moduledoc """
  A PageSection is an individual stream content area. An example is:

      %PageSection{
        # Title of the section
        title: "Live Band",
        # How the category should show up, eg: half, full
        layout: "full",
        # Size of the bootstrap column for the entire section
        bs_parent_class: "col-md-6",
        # Size of the bootstrap columns for the individiual streams
        bs_child_class: "col-md-6",
        # Channels that should be shown in order
        channels: Glimesh.Streams.list_live_channels()
      }
  """
  defstruct [:title, :layout, :bs_parent_class, :bs_child_class, :channels]
end
