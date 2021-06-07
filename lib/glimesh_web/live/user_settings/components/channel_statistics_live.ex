defmodule GlimeshWeb.UserSettings.Components.ChannelStatisticsLive do
<<<<<<< HEAD
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelStatistics
  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups

  def mount(_params, session, socket) do
    streamer = Accounts.get_user_by_session_token(session["user_token"])

    case ChannelLookups.get_channel_for_user(streamer) do
      %Glimesh.Streams.Channel{} = channel ->
        {:ok,
         socket
         |> assign(:channel, channel)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
=======
  	use GlimeshWeb, :live_view
	
  	alias Glimesh.Accounts
	alias Glimesh.ChannelLookups
  	alias Glimesh.ChannelStatistics

  	def mount(_params, session, socket) do
    	streamer = Accounts.get_user_by_session_token(session["user_token"])
		case ChannelLookups.get_channel_for_user(streamer) do
  			%Glimesh.Streams.Channel{} = channel ->
				{:ok, 
				socket
				|> assign(:channel, channel)
			}  	
  			nil ->
  				
			    {:ok, redirect(socket, to: "/")}

  		end
  	end
>>>>>>> 907b96f996a6486d4fc80dfda45725a2b44b4643
end
