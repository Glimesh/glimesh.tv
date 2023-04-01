// Disable Tracking for any libraries we may use
window.HELP_IMPROVE_VIDEOJS = false;

import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar"

topbar.config({ barColors: { 0: "#63efd6" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

import LivePlayer from "./hooks/LivePlayer";

// import BSN from "bootstrap.native";
// import bsCustomFileInput from "bs-custom-file-input";

// import ProcessPayment from './hooks/ProcessPayment';
// import Chat from './hooks/Chat';
// import Choices from "./hooks/Choices";
// import FtlVideo from "./hooks/FtlVideo";
// import ClickToCopy from "./hooks/ClickToCopy";
// import LineChart from "./hooks/charts/LineChart";
// import InfiniteScroll from "./hooks/InfiniteScroll";
// import TagSearch from "./hooks/TagSearch";
// import LaunchCountdown from "./hooks/LaunchCountdown";
// import Tagify from "./hooks/Tagify";
// import ChannelLookupTypeahead from "./hooks/ChannelLookupTypeahead";
// import RecentTags from "./hooks/RecentTags";
// import Bootstrapize from "./hooks/Bootstrapize";
// import RaidToast from "./hooks/RaidToast";
// import RaidTimer from "./hooks/RaidTimer";
// import MastodonShareButton from "./hooks/MastodonShareButton";
// import TenorSearch from "./hooks/TenorSearch";

// // https://github.com/github/markdown-toolbar-element
// import "@github/markdown-toolbar-element";

// // https://github.com/github/time-elements
// import "@github/time-elements";

// import SurfaceHooks from "./_hooks";
// // New fancy surface hooks
// let Hooks = SurfaceHooks;
// // Add in our legacy hooks
// Hooks.ProcessPayment = ProcessPayment;
// Hooks.Chat = Chat;
// Hooks.Choices = Choices;
// Hooks.FtlVideo = FtlVideo;
// Hooks.ClickToCopy = ClickToCopy;
// Hooks.LineChart = LineChart;
// Hooks.InfiniteScroll = InfiniteScroll;
// Hooks.TagSearch = TagSearch;
// Hooks.LaunchCountdown = LaunchCountdown;
// Hooks.Tagify = Tagify;
// Hooks.ChannelLookupTypeahead = ChannelLookupTypeahead;
// Hooks.RecentTags = RecentTags;
// Hooks.Bootstrapize = Bootstrapize;
// Hooks.RaidToast = RaidToast;
// Hooks.RaidTimer = RaidTimer;
// Hooks.MastodonShareButton = MastodonShareButton;
// Hooks.TenorSearch = TenorSearch;

let Hooks = {};
Hooks.LivePlayer = LivePlayer;

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken
    },
    hooks: Hooks
});
liveSocket.enableDebug();

// // Make sure no dropdown form's are automatically closed on action
// function ignoreDropdownFormClosing() {
//     document.querySelectorAll('.dropdown-menu form').forEach(function (el) {
//         el.onclick = function (e) { e.stopPropagation(); }
//     });
// }

// // Init the file upload handler
// bsCustomFileInput.init();
// ignoreDropdownFormClosing();
// window.BSN = BSN;
// window.BSN.initCallback(document.body);

// // Show progress bar on live navigation and form submits
// window.addEventListener("phx:page-loading-start", () => { });
// window.addEventListener("phx:page-loading-stop", info => {
//     if (info.detail && info.detail.kind && info.detail.kind === "initial") {
//         // Only do a full reload of dom whenever the entire page changes 
//         window.BSN.initCallback(document.body);
//         bsCustomFileInput.init();

//         // Close the nav bar on navigate
//         if (document.getElementById("primaryNav")) {
//             document.getElementById("primaryNav").classList.remove('show');
//         }
//     }

//     ignoreDropdownFormClosing();
// });

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug();
// liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

console.log("Welcome to Glimesh!");