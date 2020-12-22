import {
    FtlPlayer
} from "janus-ftl-player";


export default {
    mounted() {
        let container = this.el;
        
        this.handleEvent("load_video", ({janus_uri, channel_id}) => {
            let player = new FtlPlayer(container, janus_uri);
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
    }
};