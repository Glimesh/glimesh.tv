export default class WHEPPlayer {
    constructor(container, endpoint) {
        this.container = container;
        this.endpoint = endpoint;
        this.debug = false;
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
        // let url = this.endpoint + channel_id;
        let url = "https://live.glimesh.tv/v1/whep/endpoint/16791"
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
    enableDebug() {
        this.log("Enabling debug")
        this.debug = true;

        this.debugChannel = this.pc.createDataChannel('debug');
        this.debugChannel.addEventListener("open", (event) => this.log("Debug data channel open"));
        this.debugChannel.addEventListener("close", (event) => this.log("Debug data channel closed"));
        this.debugChannel.addEventListener("message", (event) => this.log(event.data));
    }
    disableDebug() {
        this.log("Disabling debug")
        this.debug = false;

        if (this.debugChannel) {
            this.debugChannel.close();
        }
    }
    destroy() {
        if (this.pc) {
            this.pc.close();
            this.disableDebug()
        }
    }
    log(...args) {
        console.log("WHEP:", ...args)
    }
}