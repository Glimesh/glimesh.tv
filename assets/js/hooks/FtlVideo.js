import {
    FtlPlayer
} from "janus-ftl-player";

let player;

export default {
    mounted() {
        let parent = this;
        let container = this.el;
        let videoLoadingContainer = document.getElementById("video-loading-container");
        let forceMuted = container.dataset.muted;
        let backend = container.dataset.backend;
        let saveVolumeChanges = false
        let currentlyInUltrawide = false;

        // Handle 21:9 aspect ratio monitors/browsers
        let containerParent = container.parentElement;
        // Get browser aspect ratio
        let size = {
            width: window.innerWidth || document.body.clientWidth,
            height: window.innerHeight || document.body.clientHeight
        }
        let currentAspectRatio = size.width / size.height;
        if (currentAspectRatio > 2.3) {
            // We assume this is an ultrawide of some sort
            parent.pushEvent("ultrawide", { enabled: true });
            currentlyInUltrawide = true;
        }

        // Check for WebRTC support
        if (!window.RTCPeerConnection) {
            // WebRTC is not enabled / supported in the browser
            parent.pushEvent("webrtc_error", "WebRTC is not enabled in your browser.");
            return;
        }

        this.handleEvent("load_video", ({ janus_url, channel_id }) => {
            videoLoadingContainer.classList.add("loading");

            if (backend == "ftl") {
                player = new FtlPlayer(container, janus_url, {
                    hooks: {
                        janusSlowLink(uplink, lostPackets) {
                            parent.pushEvent("lost_packets", {
                                uplink: uplink,
                                lostPackets: lostPackets
                            });
                            console.debug(`GLIMESH.TV LOST PACKETS uplink=${uplink} lostPackets=${lostPackets}`)
                        }
                    }
                });

                console.debug(`FTL backend load_video event for janus_url=${janus_url} channel_id=${channel_id}`)

                player.init(channel_id);
            } else if (backend == "whep") {
                player = new WHEPPlayer(container, "https://rtrouter.fly.dev/v1/whep/endpoint/");

                console.debug(`WHEP backend load_video event for endpoint=${janus_url} channel_id=${channel_id}`)

                player.init(channel_id).catch(error => {
                    console.error(error);
                    parent.pushEvent("webrtc_error", error.message)
                });
            }

            saveVolumeChanges = true;
        });

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

        container.addEventListener("waiting", function () {
            videoLoadingContainer.classList.add("loading");
        });

        container.addEventListener("abort", function () {
            videoLoadingContainer.classList.add("loading");
        });

        container.addEventListener("playing", function () {
            videoLoadingContainer.classList.remove("loading");
        });

        window.onresize = function () {
            // Get current aspect ratio
            let size = {
                width: window.innerWidth || document.body.clientWidth,
                height: window.innerHeight || document.body.clientHeight
            }
            let currentAspectRatio = size.width / size.height;
            if (currentAspectRatio > 2.3) {
                if (!currentlyInUltrawide) {
                    parent.pushEvent("ultrawide", { enabled: true });
                }
                currentlyInUltrawide = true;
            } else {
                if (currentlyInUltrawide) {
                    parent.pushEvent("ultrawide", { enabled: false });
                }
                currentlyInUltrawide = false;
            }
        }
    },
    destroyed() {
        if (player) {
            player.destroy();
        }
    }
};

class WHEPPlayer {
    constructor(container, endpoint) {
        this.container = container;
        this.endpoint = endpoint;
    }
    async init(channel_id) {
        this.log("Initializing player")
        this.pc = new RTCPeerConnection({});

        this.pc.addEventListener("track", event => {
            this.log("ON TRACK", event);
            this.container.srcObject = event.streams[0];
        });
        this.pc.addEventListener("iceconnectionstatechange", ev => this.log(ev));
        this.pc.addEventListener("icecandidate", ev => this.log(ev));
        this.pc.addEventListener("negotiationneeded", ev => this.log(ev));

        // let url = this.endpoint + "/" + channel_id;
        let url = this.endpoint + channel_id;
        const resp = await fetch(url, {
            method: 'POST',
            redirect: 'follow',
            mode: 'cors',
            cache: 'no-cache',
            headers: {
                'Accept': 'application/sdp'
            },
            body: ""
        });
        if (resp.status !== 201) {
            throw new Error("WebRTC failed to negotiate offer from server.");
        }

        let body = await resp.text();

        let sdp = new RTCSessionDescription({
            type: "offer",
            sdp: body
        });
        this.log("before remote description")
        await this.pc.setRemoteDescription(sdp);
        this.log("after remote description")

        let answer = await this.pc.createAnswer();
        this.log("after createAnswer");
        await this.pc.setLocalDescription(answer);
        this.log("after setLocalDescription");

        let answerHandshake = await fetch(resp.headers.get("location"), {
            method: "PATCH",
            headers: {
                'Accept': 'application/sdp'
            },
            body: answer.sdp
        });

        if (answerHandshake.status !== 204) {
            throw new Error("WebRTC failed to negotiate answer with server.");
        }
    }
    destroy() {
        if (this.pc) {
            this.pc.close();
        }
    }
    log(...args) {
        console.log("WHEP:", ...args)
    }
}