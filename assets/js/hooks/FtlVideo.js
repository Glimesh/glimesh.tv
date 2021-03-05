import {
    FtlPlayer
} from "janus-ftl-player";

let player; 

export default {
    mounted() {
        let container = this.el;

        this.handleEvent("load_video", ({janus_url, channel_id}) => {
            player = new FtlPlayer(container, janus_url);
            console.debug(`load_video event for janus_url=${janus_url} channel_id=${channel_id}`)
            player.init(channel_id);
        });

        let lastVolume = localStorage.getItem("player-volume");
        if (lastVolume) {
            container.volume = parseFloat(lastVolume);
        }

        container.addEventListener("volumechange", (event) => {
            if (container.volume) {
                localStorage.setItem("player-volume", container.volume);
            }
        });
     
        container.addEventListener("loadeddata", function() {
            let playPromise = container.play();
            if (playPromise !== undefined) {
                playPromise.then(_ => {
                  // Autoplay started!
                }).catch(error => {
                    container.muted = true;
                    container.play();
                });
              }
        })
    },
    destroyed() {
        if(player) {
            player.destroy();
        }
    }
};