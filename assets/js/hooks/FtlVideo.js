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
        let saveVolumeChanges = false;

        this.handleEvent("load_video", ({janus_url, channel_id}) => {
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
            console.debug(`load_video event for janus_url=${janus_url} channel_id=${channel_id}`)
            player.init(channel_id);

            // Ensure we only save volume changes after the stream has been loaded.
            saveVolumeChanges = true;
        }); 

        if(forceMuted) {
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
            if (saveVolumeChanges && container.volume >=0) {
                localStorage.setItem("player-volume", container.volume);
            }
        });
     
        container.addEventListener("loadeddata", function() {
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

        container.addEventListener("waiting", function() {
            videoLoadingContainer.classList.add("loading");
        });
        
        container.addEventListener("abort", function() {
            videoLoadingContainer.classList.add("loading");
        });

        container.addEventListener("playing", function() {
            videoLoadingContainer.classList.remove("loading");
        });
    },
    destroyed() {
        if(player) {
            player.destroy();
        }
    }
};