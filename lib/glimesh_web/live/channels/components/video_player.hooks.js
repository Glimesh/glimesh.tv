import WHEPPlayer from "../WhepPlayer";


let VideoPlayer = {
    player: null,
    ready: false,
    mounted() {
        console.log("VideoPlayer mounted");
    },
    updated() {
        if (this.ready) {
            return;
        }
        console.log("VideoPlayer updated");

        let parent = this;
        let container = this.el;
        let videoLoadingContainer = document.getElementById("video-loading-container");

        if (container.dataset.status == "ready") {
            this.ready = true;

            let rtrouterUrl = container.dataset.rtrouter || "";
            let channel_id = parseInt(container.dataset.channelId);

            if (container.muted == false) {
                // Otherwise, get the last known volume level.
                let lastVolume = localStorage.getItem("player-volume");
                if (lastVolume && lastVolume >= 0) {
                    container.volume = parseFloat(lastVolume);
                }
            }

            this.player = new WHEPPlayer(container, rtrouterUrl);

            console.debug(`WHEP backend load_video event for endpoint=${rtrouterUrl} channel_id=${channel_id}`)

            this.player.init(channel_id).catch(error => {
                console.error(error);
                parent.pushEvent("webrtc_error", error.message)
            });

            container.addEventListener("volumechange", (event) => {
                if (container.muted == false && container.volume >= 0) {
                    parent.saveVolume(container.volume);
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

            container.addEventListener("waiting", function () {
                videoLoadingContainer.classList.add("loading");
            });

            container.addEventListener("abort", function () {
                videoLoadingContainer.classList.add("loading");
            });

            container.addEventListener("playing", function () {
                videoLoadingContainer.classList.remove("loading");
            });
        }
    },
    destroyed() {
        if (this.player) {
            this.player.destroy();
        }
    },
    saveVolume(volume) {
        console.info("Saving volume ", volume)
        localStorage.setItem("player-volume", volume);
    }
};

export { VideoPlayer };