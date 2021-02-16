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
import bsCustomFileInput from "bs-custom-file-input";

import ProcessPayment from './hooks/ProcessPayment';
import Chat from './hooks/Chat';
import Choices from "./hooks/Choices";
import FtlVideo from "./hooks/FtlVideo";
import ClickToCopy from "./hooks/ClickToCopy";
import LineChart from "./hooks/charts/LineChart";
import InfiniteScroll from "./hooks/InfiniteScroll";
import TagSelector from "./hooks/TagSelector";
import LaunchCountdown from "./hooks/LaunchCountdown";

// https://github.com/github/markdown-toolbar-element
import "@github/markdown-toolbar-element";

// https://github.com/github/time-elements
import "@github/time-elements";

let Hooks = {};
Hooks.ProcessPayment = ProcessPayment;
Hooks.Chat = Chat;
Hooks.Choices = Choices;
Hooks.FtlVideo = FtlVideo;
Hooks.ClickToCopy = ClickToCopy;
Hooks.LineChart = LineChart;
Hooks.InfiniteScroll = InfiniteScroll;
Hooks.TagSelector = TagSelector;
Hooks.LaunchCountdown = LaunchCountdown;

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken
    },
    hooks: Hooks
});

// Make sure no dropdown form's are automatically closed on action
function ignoreDropdownFormClosing() {
    document.querySelectorAll('.dropdown-menu form').forEach(function(el) { 
        el.onclick = function(e) { e.stopPropagation(); } 
    })
}

// Init the file upload handler
bsCustomFileInput.init();
ignoreDropdownFormClosing()

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", () => {});
window.addEventListener("phx:page-loading-stop", info => {
    if (info.detail && info.detail.kind && info.detail.kind === "initial") {
        // Only do a full reload of dom whenever the entire page changes 
        BSN.initCallback(document.body);
        bsCustomFileInput.init();

        // Close the nav bar on navigate
        if (document.getElementById("primaryNav")) {
            document.getElementById("primaryNav").classList.remove('show');
        }
    }

    ignoreDropdownFormClosing()
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug();
// liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;