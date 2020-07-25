// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import BSN from "bootstrap.native";


function loadLib(url) {
    return new Promise((resolve, reject) => {
        // adding the script tag to the head as suggested before
        let head = document.getElementsByTagName('head')[0];
        let script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = url;

        // then bind the event to the callback function
        // there are several events for cross browser compatibility
        script.onreadystatechange = resolve;
        script.onload = resolve;

        // fire the loading
        head.appendChild(script);
    });
}

function tryVideo(url) {
    if (document.getElementById('player')) {
        Promise.all([
            loadLib("https://cdnjs.cloudflare.com/ajax/libs/dashjs/2.9.3/dash.all.min.js"),
            loadLib("https://cdn.jsdelivr.net/npm/hls.js@latest"),
            loadLib("/ovenplayer/ovenplayer.js"),
        ]).then(data => {
            console.log('finished loading video player with ' + url);
            // OvenPlayer.debug(true);

            let player = OvenPlayer.create("player", {
                // autoStart: true,
                image : "/images/stream-not-started.jpg",
                sources: [
                    {
                        type: "webrtc",
                        file: "wss://edge.live.glimesh.tv:3334/app/stream",
                        label: "Warp 1"
                    },
                    {
                        type: "hls",
                        file: "https://edge.live.glimesh.tv/app/stream/playlist.m3u8",
                        label: "HLS"
                    },
                    {
                        type: "mpd",
                        file: "https://edge.live.glimesh.tv/app/stream/manifest.mpd",
                        label: "MPEG-DASH"
                    }
                ]
            });
            player.on("error", function (error) {
                console.log(error);
            });
            player.on('ready', function() {
                // player.play();
            });

            player.on('metaChanged', function(f) {
                console.log(f);
                player.play();
            });

            setTimeout(function () {
            }, 5000);
        });
    }
}

let Hooks = {};
Hooks.LoadVideo = {
    playbackUrl() { return this.el.dataset.playbackUrl },
    mounted() {
        tryVideo(this.playbackUrl())
    }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => {
    console.log("phx:page-loading-stop");
    BSN.initCallback(document.body);
    NProgress.done();

    // Close the nav bar on navigate
    if(document.getElementById("primaryNav")) {
        document.getElementById("primaryNav").classList.remove('show');
    }
});
// tryVideo();

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

