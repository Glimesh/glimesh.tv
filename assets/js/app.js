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
import {
    Socket
} from "phoenix"
import {
    LiveSocket
} from "phoenix_live_view"
import BSN from "bootstrap.native";

import ProcessPayment from './hooks/ProcessPayment';
import Chat from './hooks/Chat';
import Choices from "./hooks/Choices";
import FtlVideo from "./hooks/FtlVideo";
import OvenVideo from "./hooks/OvenVideo";

// https://github.com/github/markdown-toolbar-element
import "@github/markdown-toolbar-element";

let Hooks = {};
Hooks.ProcessPayment = ProcessPayment;
Hooks.Chat = Chat;
Hooks.Choices = Choices;
Hooks.FtlVideo = FtlVideo;
Hooks.OvenVideo = OvenVideo;

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken
    },
    hooks: Hooks
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", () => {});
window.addEventListener("phx:page-loading-stop", info => {
    BSN.initCallback(document.body);

    // Close the nav bar on navigate
    if (document.getElementById("primaryNav")) {
        document.getElementById("primaryNav").classList.remove('show');
    }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug();
// liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;
