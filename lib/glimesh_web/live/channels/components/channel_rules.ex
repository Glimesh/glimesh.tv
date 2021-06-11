defmodule GlimeshWeb.Channels.ChannelRulesComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use GlimeshWeb, :live_component

  def render(assigns) do
    ~L"""
    <%= if @rules do %>
    <%= @rules %>
    <% else %>
    <h3>Chat Rules</h3>
    <p>1. <strong>Hate Speech</strong> - Hate Speech is not tolerated by Glimesh under any circumstances. Any
        message that promotes, encourages, or facilitates discrimination, denigration, objectification, harassment,
        or violence based on race, age, sexuality, physical characteristics, gender identity, disability, military
        service, religion and/or nationality will be considered hate speech is prohibited. We don't allow the use of
        hateful slurs of any kind. If you have to question whether your message violates this rule, don't send it.</p>
    <p>2. <strong>Harassment</strong> - We want you, as a member of our community, to feel safe and respected so
        you can engage and connect with others. Harassment or bullying of other community members or the streamer
        will not be tolerated. Harassment is considered any message or activity with the intention to intimidate,
        degrade, abuse, or bully others, or creates a hostile environment for others. Telling the streamer or
        another user to "kill yourself" is unacceptable. If the streamer or another community member asks you not to
        make certain remarks, and you continue, that is harassment. If the streamer's rules say such comments are
        not welcome, it is harassment.</p>
    <p>3. <strong>Threats & Violence</strong> - All threats will be taken seriously by the moderators and Glimesh
        team. This includes threats of harm to others, threats of swatting, threats of doxing, threats of DDoS and
        threats of harassment.</p>
    <p>4. <strong>Spam</strong> - No one likes spam. Spam is considered posting large amounts of repetitive,
        unwanted messages in a short amount of time.</p>
    <p>5. <strong>Personal Information</strong> - Posting personal information about others without their consent
        (“doxxing") is not allowed. It is prohibited to share content that may reveal private personal information
        about individuals, or their private property, without permission.</p>
    <% end %>
    """
  end

  defp default_rules do
    """

    """
  end
end
