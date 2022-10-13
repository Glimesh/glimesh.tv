defmodule GlimeshWeb.About.GoLiveLive do
  use GlimeshWeb, :surface_live_view

  @impl true
  def render(assigns) do
    ~F"""
    <div class="container mb-4">
      <h1 class="display-3 text-center">Go Live on Glimesh</h1>

      <div class="row">
        <div class="col">
          <div class="card">
            <div class="card-body">
              <h2>Streaming Directly</h2>
              <p>You can stream to Glimesh directly using most any of your favorite tools! Applications like OBS and Streamlabs support Glimesh out of the box, and other software can easily be configured to work with Glimesh by using the settings & ingest locations found below.</p>
              <hr>

              <h3>
                <a href="https://obsproject.com/" targe="_blank" class="text-color-link text-color-link-no-hover">
                  <img
                    height="40"
                    src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/go-live/obs-small-icon.png")}
                    alt="OBS Studio Logo"
                  /> OBS Studio
                </a>
              </h3>

              <p>OBS Studio is the recommended program for streaming to Glimesh as it has native support for our Low Latency FTL & RTMP protocols, setting it up to stream is as simple as finding it in the services list and hitting Start Streaming.</p>
              <p>Most users who are streaming to Glimesh directly should use the "Glimesh" dropdown, as it has the best technology. However if you are experiencing issues, you can try the "Glimesh - RTMP" option.</p>

              <a href="https://support.glimesh.tv/en-us/7-stream-settings/26-obs-studio-setup-guide">Full OBS Setup Guide</a>

              <h3 class="mt-4">
                <a
                  href="https://streamlabs.com/streamlabs-live-streaming-software"
                  targe="_blank"
                  class="text-color-link text-color-link-no-hover"
                >
                  <img
                    height="40"
                    src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/go-live/streamlabs-small-icon.png")}
                    alt="Streamlabs Logo"
                  /> Streamlabs Desktop
                </a>
              </h3>

              <p>You can stream to Glimesh with Streamlabs Desktop, however only basic features like streaming are currently supported.</p>

              <a href="https://support.glimesh.tv/en-us/7-stream-settings/113-slobs-setup-guide">Full Streamlabs Desktop Setup Guide</a>

              <div class="alert alert-primary mt-4" role="alert">
                Looking for RTMP in OBS? Due to some delays with OBS & Streamlabs Desktop updating their services file, you may need to run the <a
                  href="https://support.glimesh.tv/en-us/7-stream-settings/112-adding-glimesh-as-a-stream-service-in-obs-or-streamlabs-desktop"
                  target="_blank"
                >Glimesh Patcher</a> to see "Glimesh - RTMP" as an option.
              </div>

              <h3 class="mt-4">Other Software</h3>
              <p>Most software should support either FTL or RTMP. You'll need to find out which one, and then grab a streaming URL from a location close to you. Some changes to your video output settings will be required to get the best experience!</p>
            </div>
          </div>
        </div>
        <div class="col">
          <div class="card">
            <div class="card-body">
              <h2>Multi-Streaming</h2>
              <p>If you want to add Glimesh to your already existing arsenal of platforms, that's easy too! If you are using Aircast, just find Glimesh in the list. If you are using other providers, some custom configuration will be required.</p>
              <hr>

              <h3>
                <a href="https://airca.st/" targe="_blank" class="text-color-link text-color-link-no-hover">
                  <img
                    :if={@site_theme == "dark"}
                    height="40"
                    src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/go-live/aircast-small-logo-dark.png")}
                    alt="aircast"
                  />
                  <img
                    :if={@site_theme == "light"}
                    height="40"
                    src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/go-live/aircast-small-logo-light.png")}
                    alt="aircast"
                  />
                </a>
              </h3>

              <p>Aircast has native support for our super low latency FTL & RTMP technology and has worked collaboratively with Glimesh from the very beginning. With just one click you can enable integrations to stream to Glimesh, and many other platforms at the same time.</p>

              <p :if={show_aircast_promo()} class="text-warning">For a limited time, get 20% off a new Aircast subscription (for 12 months!) using the coupon code GLIMESHRTMP at checkout.</p>

              <h3>Other Providers</h3>
              <p>You can easily configure multi-streaming with providers like Restream, or dedicated apps like Streamlabs Desktop's multistreaming to work with Glimesh. You'll need an RTMP url from below to get started <strong>and to change some basic settings to get the best experience.</strong></p>
            </div>
          </div>
        </div>
      </div>

      {#if @stream_key}
        <div class="card mt-4">
          <div class="card-body">
            <div class="form-group">
              <h3>{gettext("Your Stream Key")}</h3>
              <p class="text-muted form-text">
                {gettext(
                  "A key used to uniquely identify and connect to your stream. Treat your Stream Key as a password."
                )}
              </p>
              <div class="input-group">
                <input type="text" value={@stream_key} class="form-control stream-key" readonly="readonly">

                <div class="input-group-append">
                  {live_render(@socket, GlimeshWeb.Components.ClickToCopy,
                    id: "stream_key_copy",
                    session: %{"value" => @stream_key}
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      {/if}

      <div class="accordion mt-4" id="accordionExample">
        <div class="card">
          <div class="card-header" id="headingOne">
            <h2 class="mb-0">
              <button
                class="btn btn-link btn-block text-left text-color-link"
                type="button"
                data-toggle="collapse"
                data-target="#collapseOne"
                aria-expanded="false"
                aria-controls="collapseOne"
              >
                Advanced Settings for Other Streaming Software
              </button>
            </h2>
          </div>

          <div
            id="collapseOne"
            class="collapse"
            aria-labelledby="headingOne"
            data-parent="#accordionExample"
          >
            <div class="card-body">
              <div class="row">
                <div class="col">
                  <h3>Video Settings</h3>
                  <p>If using our dropdowns in OBS or Streamlabs Desktop, these changes will likely already be done for you!</p>
                  <p>It's <strong>very important</strong> to disable b-frames as they cause stream stuttering.</p>
                  <table class="table table-borderless">
                    <thead>
                      <tr>
                        <th>Setting</th>
                        <th>Recommendation</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <th>Video Bitrate Cap</th>
                        <td>6000 Kbps</td>
                      </tr>
                      <tr>
                        <th>B-Frames</th>
                        <td>0</td>
                      </tr>
                      <tr>
                        <th>Keyframe Interval</th>
                        <td>1 or 2 seconds</td>
                      </tr>
                      <tr>
                        <th>Resolution</th>
                        <td>1280x720 or 1920x1080</td>
                      </tr>
                      <tr>
                        <th>Frame Rate</th>
                        <td>30fps or 60fps</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <div class="col">
                  <h3>Ingest Locations</h3>
                  <p>Since Glimesh focuses on low-latency, we have several ingest locations around the world that are available. Use whichever protocol your streaming software supports.</p>
                  <div class="overflow-auto" style="max-height: 300px">
                    <table class="table table-borderless table-sm">
                      <thead class="bg-color-card" style="position: sticky; top: 0;">
                        <tr>
                          <th>FTL Address</th>
                          <th>RTMP URL</th>
                        </tr>
                      </thead>
                      <tbody>
                        {#for {location, url} <- ingest_servers()}
                          <tr>
                            <th colspan="2">{location}</th>
                          </tr>
                          <tr>
                            <td>{url}</td>
                            <td>rtmp://{url}/live</td>
                          </tr>
                        {/for}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="row mt-4">
        <div class="col">
          <div class="card">
            <div class="card-body">
              <h2>Payments</h2>
              <p>Setting up payments on Glimesh is simple, and doesn't have any metric or popularity requirements. To setup your
                <button class="btn btn-secondary btn-sm">
                  <i class="fas fa-hand-holding-usd fa-fw" />{gettext("Support")}
                </button>
                button, visit your <a href="">Payments</a> page to start the process.</p>
              <p>All channels have access to Subscriptions, Gift Subs, and Donations.</p>
              <ul>
                <li>🌎 80+ countries supported</li>
                <li>📆 Bi-weekly payouts</li>
                <li>💳 No payout minimum</li>
                <li>⚡️ Instant setup</li>
                <li>✅ No number requirements</li>
                <li>⚖️ 60% sub cut, we pay the fees</li>
                <li>💸 No Glimesh cut on donations</li>
                <li>🛡 100% charge-back protection</li>
                <li>⛑ No personal data stored on Glimesh</li>
              </ul>
              <p>We do not currently support Paypal or other payment providers.</p>
            </div>
          </div>
        </div>
        <div class="col">
          <div class="card">
            <div class="card-body">
              <h2>3rd Party Addons</h2>
              <p>Many 3rd parties you are used to support Glimesh. We're also fortunate to have a very active developer community constantly building things for the Glimesh community!</p>

              <h3>Chat Bots</h3>
              <ul class="list-inline">
                {#for {name, url} <- bots()}
                  <li class="list-inline-item"><a href={url} target="_blank">{name}</a></li>
                {/for}
              </ul>

              <h3>Overlays / Alerts</h3>
              <ul class="list-inline">
                {#for {name, url} <- overlays()}
                  <li class="list-inline-item"><a href={url} target="_blank">{name}</a></li>
                {/for}
              </ul>

              <h3>Other</h3>
              <ul class="list-inline">
                {#for {name, url} <- other()}
                  <li class="list-inline-item"><a href={url} target="_blank">{name}</a></li>
                {/for}
              </ul>

              <p>Many more 3rd parties are available, you can find a full list of them in our Discord server.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:page_title, "Go Live on Glimesh")
     |> assign(:site_theme, Map.get(session, "site_theme", "dark"))
     |> assign(:custom_meta, %{
       title: "Going Live on Glimesh.tv",
       description:
         "Learn how to configure your streaming client of choice and get started streaming on Glimesh instantly!",
       image_url:
         Routes.static_url(GlimeshWeb.Endpoint, "/images/about/go-live/social-media-preview.png"),
       card_type: "summary_large_image"
     })
     |> assign(:stream_key, get_stream_key(session))}
  end

  defp get_stream_key(%{"user_token" => user_token}) do
    with %Glimesh.Accounts.User{} = user <-
           Glimesh.Accounts.get_user_by_session_token(user_token),
         true = user.can_stream,
         %Glimesh.Streams.Channel{} = channel <- Glimesh.ChannelLookups.get_channel_for_user(user) do
      Glimesh.Streams.get_stream_key(channel)
    else
      _ ->
        nil
    end
  end

  defp get_stream_key(_), do: nil

  defp ingest_servers do
    [
      {"North America - Chicago, United States", "ingest.kord.live.glimesh.tv"},
      {"North America - New York, United States", "ingest.kjfk.live.glimesh.tv"},
      {"North America - San Francisco, United States", "ingest.ksfo.live.glimesh.tv"},
      {"North America - Toronto, Canada", "ingest.cyyz.live.glimesh.tv"},
      {"South America - Sao Paulo, Brazil", "ingest.sbgr.live.glimesh.tv"},
      {"Europe - Amsterdam, Netherlands", "ingest.eham.live.glimesh.tv"},
      {"Europe - Frankfurt, Germany", "ingest.eddf.live.glimesh.tv"},
      {"Europe - London, United Kingdom", "ingest.egll.live.glimesh.tv"},
      {"Asia - Bangalore, India", "ingest.vobl.live.glimesh.tv"},
      {"Asia - Singapore", "ingest.wsss.live.glimesh.tv"},
      {"Australia - Sydney, Australia", "ingest.yssy.live.glimesh.tv"}
    ]
  end

  defp bots do
    %{
      "BeepBot" => "https://beepbot.app/",
      "Oaty" => "https://oaty.app/",
      "Mix It Up" => "https://mixitupapp.com/",
      "GlimBoi" => "https://glimboi.com/",
      "Glimli" => "https://glimli.com/"
    }
  end

  defp overlays do
    %{
      "Pixel Chat" => "https://pixelchat.tv/",
      "Chameolabs" => "https://chameolabs.com/#/",
      "GlimChat" => "https://glimchat.burrito.software/",
      "Casterlabs" => "https://casterlabs.co/",
      "Glimli" => "https://glimli.com/"
    }
  end

  defp other do
    %{
      "Lumiastream" => "https://lumiastream.com/",
      "Jimnet" => "https://jimnet.net/chatdash",
      "StreamLoots" => "https://www.streamloots.com/",
      "CouchBot" => "https://couch.bot/"
    }
  end

  defp show_aircast_promo do
    today = Date.utc_today()
    today.year == 2022 && today.month in [10, 11]
  end
end
