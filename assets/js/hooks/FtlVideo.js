import {
    FtlPlayer
} from "janus-ftl-player";

let player; 

export default {
    mounted() {
        let container = this.el;
        
        this.handleEvent("load_video", ({janus_url, channel_id}) => {
            player = new FtlPlayer(container, janus_url);
            let init = player.init(channel_id);
        })

        container.addEventListener("loadeddata", function() {
            let playPromise = container.play();
            if (playPromise !== undefined) {
                playPromise.then(_ => {
                  // Autoplay started!
                }).catch(error => {
                    alert("Video autoplay was prevented by your browser, hit the Play button!")
                });
              }
        })
    },
    destroyed() {
        if(player) {player.destroy();}
    }
};