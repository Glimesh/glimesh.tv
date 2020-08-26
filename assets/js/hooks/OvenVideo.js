function loadLib(url) {
    return new Promise((resolve, reject) => {
        // adding the script tag to the head as suggested before
        let head = document.getElementsByTagName('head')[0];
        let script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = url;

        // then bind the event to the callback function
        // there are several events for cross browser compatibility
        script.onreadystatechange = resolve;
        script.onload = resolve;

        // fire the loading
        head.appendChild(script);
    });
}


export default {
    mounted() {
        if (document.getElementById('player')) {
            Promise.all([
                loadLib("https://cdnjs.cloudflare.com/ajax/libs/dashjs/2.9.3/dash.all.min.js"),
                loadLib("https://cdn.jsdelivr.net/npm/hls.js@latest"),
                loadLib("/ovenplayer/ovenplayer.js"),
            ]).then(data => {

                let player = OvenPlayer.create("player", {
                    // autoStart: true,
                    image: "/images/stream-not-started.jpg",
                    sources: [{
                            type: "webrtc",
                            file: "wss://edge.live.glimesh.tv:3334/app/stream",
                            label: "Warp 1"
                        },
                        {
                            type: "hls",
                            file: "https://edge.live.glimesh.tv/app/stream/playlist.m3u8",
                            label: "HLS"
                        },
                        {
                            type: "mpd",
                            file: "https://edge.live.glimesh.tv/app/stream/manifest.mpd",
                            label: "MPEG-DASH"
                        }
                    ]
                });
                player.on("error", function (error) {
                    console.log(error);
                });

                player.on('metaChanged', function (f) {
                    player.play();
                });
            });
        }
    }
};