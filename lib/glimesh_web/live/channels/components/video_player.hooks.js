import {
    FtlPlayer
} from "janus-ftl-player";


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

            let janus_url = container.dataset.janusUrl;
            let channel_id = parseInt(container.dataset.channelId);

            if(container.muted == false) {
                // Otherwise, get the last known volume level.
                let lastVolume = localStorage.getItem("player-volume");
                if (lastVolume && lastVolume >= 0) {
                    container.volume = parseFloat(lastVolume);
                }
            }

            this.player = new FtlPlayer(container, janus_url, {
                hooks: {
                    janusSlowLink(uplink, lostPackets) {
                        // parent.pushEvent("lost_packets", {
                        //     uplink: uplink,
                        //     lostPackets: lostPackets
                        // });
                        console.debug(`GLIMESH.TV LOST PACKETS uplink=${uplink} lostPackets=${lostPackets}`)
                    }
                }
            }); 
    
            console.debug(`load_video event for janus_url=${janus_url} channel_id=${channel_id}`)
            this.player.init(channel_id);
    
            container.addEventListener("volumechange", (event) => {
                if (container.muted == false && container.volume >=0) {
                    parent.saveVolume(container.volume);
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
        }
    },
    destroyed() {
        if(this.player) {
            this.player.destroy();
        }
    },
    saveVolume(volume) {
        console.info("Saving volume ", volume)
        localStorage.setItem("player-volume", volume);
    }
};

export {VideoPlayer};