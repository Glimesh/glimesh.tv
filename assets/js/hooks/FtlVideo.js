import {
    FtlPlayer
} from "janus-ftl-player";


export default {
    janusServerUri() {
        return this.el.dataset.janusServerUri;
    },
    channelId() {
        return parseInt(this.el.dataset.channelId);
    },
    mounted() {
        let player = new FtlPlayer(this.el, this.janusServerUri());
        player.init(this.channelId());
    }
};