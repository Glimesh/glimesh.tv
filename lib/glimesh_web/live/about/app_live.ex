defmodule GlimeshWeb.About.AppLive do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container" style="max-width: 2200px; padding-left: 0; padding-right: 0;">
      <div style="background-color: #5271fd;">
        <div class="row mb-4">
          <div class="col d-none d-md-flex align-items-center">
            <img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/app-demo.gif")}>
          </div>
          <div class="col d-flex flex-column justify-content-center">
            <h1 class="display-3 text-center m-4" style="font-family: Roboto;">The app is here!</h1>

            <p class="text-center lead mt-4">Finally, Glimesh from the comfort of your phone or tablet. Download it now!</p>

            <div class="row mx-4 mt-0 text-center">
              <div class="col-12 col-sm-6 px-4"><a href="https://testflight.apple.com/join/0gxM8YIG" target="_blank"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/download-on-the-app-store.png")}></a></div>
              <div class="col-12 col-sm-6 px-4"><a href="https://play.google.com/store/apps/details?id=tv.glimesh.app" target="_blank"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/get-it-on-google-play.png")}></a></div>
            </div>
          </div>
        </div>

        <div class="row no-gutters">
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 1.jpg")}></div>
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 2.jpg")}></div>
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 3.jpg")}></div>
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 4.jpg")}></div>
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 5.jpg")}></div>
          <div class="col-6 col-sm-4 col-xl-2"><img class="img-fluid" src={Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/SC 6.jpg")}></div>
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
     |> assign(:page_title, "Mobile App")
     |> assign(:custom_meta, %{
       title: "Glimesh Mobile App",
       description:
         "The future of Glimesh is in your hands. Check out our new mobile app for iOS and Android!",
       image_url:
         Routes.static_url(GlimeshWeb.Endpoint, "/images/about/app/app-social-preview.png"),
       card_type: "summary_large_image"
     })}
  end
end
