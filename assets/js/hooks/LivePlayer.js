import WHEPPlayer from "../WhepPlayer";

let player;

export default {
    mounted() {
        let parent = this;
        let container = this.el;
        // let videoLoadingContainer = document.getElementById("video-loading-container");
        let forceMuted = container.dataset.muted;
        let backend = container.dataset.backend;
        let channel_id = container.dataset.channelId;
        let rtrouterUrl = container.dataset.rtrouter || "";
        let saveVolumeChanges = false

        // Check for WebRTC support
        if (!window.RTCPeerConnection) {
            // WebRTC is not enabled / supported in the browser
            parent.pushEvent("webrtc_error", "WebRTC is not enabled in your browser.");
            return;
        }

        // this.handleEvent("load_video", ({ janus_url, channel_id }) => {
        if (true) {
            // videoLoadingContainer.classList.add("loading");

            player = new WHEPPlayer(container, rtrouterUrl);

            console.debug(`WHEP backend load_video event for endpoint=${rtrouterUrl} channel_id=${channel_id}`)

            player.init(channel_id).catch(error => {
                console.error(error);
                parent.pushEvent("webrtc_error", error.message)
            });

            saveVolumeChanges = true;
            // });
        }

        if (forceMuted) {
            // If the parent player wants us to be muted, eg: homepage
            // container.volume = 0;
            container.muted = true;
        } else {
            // Otherwise, get the last known volume level.
            let lastVolume = localStorage.getItem("player-volume");
            if (lastVolume && lastVolume >= 0) {
                container.volume = parseFloat(lastVolume);
            }
        }

        container.addEventListener("volumechange", (event) => {
            if (saveVolumeChanges && container.volume >= 0) {
                localStorage.setItem("player-volume", container.volume);
            }
        });

        container.addEventListener("loadeddata", function () {
            let playPromise = container.play();
            if (playPromise !== undefined) {
                playPromise.then(_ => {
                    // Autoplay started!
                }).catch(error => {
                    console.error(error);
                    container.muted = true;
                    container.play();
                });
            }
        });

        // container.addEventListener("waiting", function () {
        //     videoLoadingContainer.classList.add("loading");
        // });

        // container.addEventListener("abort", function () {
        //     videoLoadingContainer.classList.add("loading");
        // });

        // container.addEventListener("playing", function () {
        //     videoLoadingContainer.classList.remove("loading");
        // });
    },
    updated() {
        let container = this.el;
        if (player && container.dataset.backend == "whep") {
            if (container.dataset.debug == "") {
                player.enableDebug();
            } else {
                player.disableDebug();
            }
        }
    },
    destroyed() {
        if (player) {
            player.destroy();
        }
    }
};
